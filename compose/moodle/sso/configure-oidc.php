<?php
// ============================================================
// CR465 - Configure le fournisseur OAuth2/OIDC Keycloak dans Moodle.
//
// A executer DANS le conteneur Moodle, avec l'utilisateur du serveur web :
//   php /tmp/configure-oidc.php
//
// Variables d'environnement attendues :
//   SSO_ISSUER_NAME     (defaut : Keycloak)
//   SSO_ISSUER_URL      URL PUBLIQUE  ex : https://auth.cr465.test/realms/cr465
//   SSO_INTERNAL_URL    URL INTERNE   ex : http://keycloak:8080/realms/cr465
//   SSO_CLIENT_ID       (defaut : moodle)
//   SSO_CLIENT_SECRET   secret du client OIDC
//
// Pourquoi deux URL : le navigateur doit joindre Keycloak par son nom public
// (HTTPS via Traefik), tandis que Moodle lui-meme le joint par le reseau
// interne (pas de DNS public, pas de certificat auto-signe a valider).
//
// Idempotent : relance = mise a jour, pas de doublon.
// ============================================================

define('CLI_SCRIPT', true);
require('/var/www/html/public/config.php');
require_once($CFG->libdir . '/clilib.php');

$name         = getenv('SSO_ISSUER_NAME') ?: 'Keycloak';
$publicbase   = rtrim(getenv('SSO_ISSUER_URL') ?: '', '/');
$internalbase = rtrim(getenv('SSO_INTERNAL_URL') ?: '', '/');
$clientid     = getenv('SSO_CLIENT_ID') ?: 'moodle';
$secret       = getenv('SSO_CLIENT_SECRET');

if (!$publicbase) {
    cli_error('SSO_ISSUER_URL manquant');
}
if (!$secret) {
    cli_error('SSO_CLIENT_SECRET manquant');
}

// Les API de configuration exigent la capacite moodle/site:config.
$admin = get_admin();
if (!$admin) {
    cli_error('Aucun administrateur Moodle trouve');
}
\core\session\manager::set_user($admin);

// Moodle bloque par defaut les URL qui resolvent vers des adresses privees
// (protection SSRF). Ici Keycloak n'est joignable que par le reseau interne :
// la segmentation reseau fait office de controle. Ecart assume, documente.
set_config('curlsecurityblockedhosts', '');
set_config('curlsecurityallowedport', '');

$data = (object) [
    'name'                => $name,
    'image'               => '',   // colonne NOT NULL dans cette version de Moodle
    'baseurl'             => $publicbase,
    'clientid'            => $clientid,
    'clientsecret'        => $secret,
    'enabled'             => 1,
    'showonloginpage'     => \core\oauth2\issuer::LOGINONLY,
    'loginscopes'         => 'openid profile email',
    'loginscopesoffline'  => 'openid profile email',
    'requireconfirmation' => 0,
];

$existing = $DB->get_record('oauth2_issuer', ['name' => $name]);
if ($existing) {
    $data->id = $existing->id;
    $issuer = \core\oauth2\api::update_issuer($data);
    mtrace("Fournisseur '{$name}' mis a jour (id={$issuer->get('id')})");
} else {
    $issuer = \core\oauth2\api::create_issuer($data);
    mtrace("Fournisseur '{$name}' cree (id={$issuer->get('id')})");
}
$issuerid = $issuer->get('id');

// --- Endpoints -------------------------------------------------------
// Tentative 1 : decouverte automatique (si le nom public est resolvable).
$discovered = false;
try {
    \core\oauth2\service\custom::discover_endpoints($issuer);
    $discovered = !empty(\core\oauth2\api::get_endpoints($issuer));
} catch (\Throwable $e) {
    mtrace('Decouverte automatique impossible : ' . $e->getMessage());
}

// Tentative 2 : endpoints declares explicitement (public pour le navigateur,
// interne pour les appels serveur a serveur).
if (!$discovered) {
    if (!$internalbase) {
        cli_error('Decouverte impossible et SSO_INTERNAL_URL non fourni');
    }
    $wanted = [
        'issuer'                 => $publicbase,
        'authorization_endpoint' => $publicbase . '/protocol/openid-connect/auth',
        'token_endpoint'         => $internalbase . '/protocol/openid-connect/token',
        'userinfo_endpoint'      => $internalbase . '/protocol/openid-connect/userinfo',
        'jwks_uri'               => $internalbase . '/protocol/openid-connect/certs',
        'end_session_endpoint'   => $publicbase . '/protocol/openid-connect/logout',
    ];
    $current = [];
    foreach (\core\oauth2\api::get_endpoints($issuer) as $ep) {
        $current[$ep->get('name')] = $ep;
    }
    foreach ($wanted as $epname => $url) {
        if (isset($current[$epname])) {
            $ep = $current[$epname];
            $ep->set('url', $url);
            $ep->update();
        } else {
            \core\oauth2\api::create_endpoint((object) [
                'issuerid' => $issuerid,
                'name'     => $epname,
                'url'      => $url,
            ]);
        }
    }
    mtrace('Endpoints declares manuellement (public/interne)');
}

// --- Activation du plugin d'authentification ------------------------
\core\plugininfo\auth::enable_plugin('oauth2', true);
mtrace('Plugin auth_oauth2 active');

// --- Verification ---------------------------------------------------
$endpoints = \core\oauth2\api::get_endpoints($issuer);
if (empty($endpoints)) {
    cli_error('Aucun endpoint configure');
}
foreach ($endpoints as $endpoint) {
    mtrace('  endpoint ' . $endpoint->get('name') . ' -> ' . $endpoint->get('url'));
}

mtrace('Base URL   : ' . $issuer->get('baseurl'));
mtrace('Client ID  : ' . $issuer->get('clientid'));
mtrace('Actif      : ' . ($issuer->get('enabled') ? 'oui' : 'non'));
mtrace('Sur login  : ' . ($issuer->get('showonloginpage') ? 'oui' : 'non'));
mtrace('SSO Moodle configure.');
