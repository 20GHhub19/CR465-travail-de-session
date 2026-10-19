<?php
// ============================================================
// CR465 - Prepare l'API web Moodle pour n8n (moindre privilege).
//
// A executer DANS le conteneur Moodle :
//   php /tmp/configure-webservice.php
//
// Actions :
//   1. active les services web + le protocole REST
//   2. cree le service externe "cr465" avec 6 fonctions
//   3. cree un compte de service "svc-n8n" (auth nologin)
//   4. cree un role technique limite (pas administrateur)
//   5. genere un jeton permanent et l'affiche
//
// Le jeton est ensuite stocke dans compose/.env (MOODLE_WS_TOKEN),
// jamais dans le depot Git.
// ============================================================

define('CLI_SCRIPT', true);
require('/var/www/html/public/config.php');
require_once($CFG->libdir . '/clilib.php');
require_once($CFG->dirroot . '/user/lib.php');
require_once($CFG->libdir . '/accesslib.php');

$admin = get_admin();
\core\session\manager::set_user($admin);
$systemcontext = context_system::instance();

// --- 1. Services web + REST ------------------------------------------
set_config('enablewebservices', 1);
set_config('webserviceprotocols', 'rest');
// Le plugin d'authentification "webservice" autorise un compte sans mot de passe
// a utiliser l'API (un compte "nologin" est explicitement refuse).
\core\plugininfo\auth::enable_plugin('webservice', true);
mtrace('Services web actives (protocole REST)');

// --- 2. Service externe ---------------------------------------------
$service = $DB->get_record('external_services', ['shortname' => 'cr465']);
if (!$service) {
    $id = $DB->insert_record('external_services', (object) [
        'name'            => 'CR465 - integration n8n',
        'shortname'       => 'cr465',
        'enabled'         => 1,
        'restrictedusers' => 0,
        'component'       => null,
        'timecreated'     => time(),
        'timemodified'    => time(),
        'downloadfiles'   => 0,
        'uploadfiles'     => 0,
    ]);
    $service = $DB->get_record('external_services', ['id' => $id]);
    mtrace('Service externe "cr465" cree');
} else {
    $service->enabled = 1;
    $DB->update_record('external_services', $service);
    mtrace('Service externe "cr465" deja present');
}

// --- 3. Fonctions exposees ------------------------------------------
$functions = [
    'core_webservice_get_site_info',
    'core_user_get_users_by_field',
    'core_user_create_users',
    'core_course_get_courses',
    'core_course_get_enrolled_users',
    'enrol_manual_enrol_users',
];
foreach ($functions as $fn) {
    $exists = $DB->record_exists('external_services_functions', [
        'externalserviceid' => $service->id,
        'functionname'      => $fn,
    ]);
    if (!$exists) {
        $DB->insert_record('external_services_functions', (object) [
            'externalserviceid' => $service->id,
            'functionname'      => $fn,
        ]);
        mtrace("  + $fn");
    }
}

// --- 4. Role technique a privilege minimal --------------------------
$role = $DB->get_record('role', ['shortname' => 'servicen8n']);
if (!$role) {
    $roleid = create_role('Service n8n', 'servicen8n', 'Role technique : API d inscription uniquement');
    $role = $DB->get_record('role', ['id' => $roleid]);
    mtrace('Role technique "servicen8n" cree');
} else {
    $roleid = $role->id;
}
$capabilities = [
    'webservice/rest:use',
    'enrol/manual:enrol',
    'moodle/role:assign',           // requis pour attribuer le role etudiant lors de l inscription
    'moodle/user:create',
    'moodle/user:viewdetails',
    'moodle/user:viewalldetails',   // sinon un utilisateur sans cours commun n'est pas visible
    'moodle/course:view',
    'moodle/course:enrolreview',
    'moodle/course:viewparticipants',
];
foreach ($capabilities as $cap) {
    assign_capability($cap, CAP_ALLOW, $roleid, $systemcontext->id, true);
}

// --- 4bis. Autoriser l'attribution du role etudiant ------------------
// Par defaut, un role nouvellement cree ne peut attribuer aucun role
// (matrice "Allow role assignments" vide). Sans cette ligne,
// enrol_manual_enrol_users echoue avec "wsusercannotassign".
$studentrole = $DB->get_record('role', ['shortname' => 'student']);
if ($studentrole && !$DB->record_exists('role_allow_assign', ['roleid' => $roleid, 'allowassign' => $studentrole->id])) {
    $DB->insert_record('role_allow_assign', (object) [
        'roleid'      => $roleid,
        'allowassign' => $studentrole->id,
    ]);
    mtrace('Attribution du role student autorisee pour servicen8n');
}

// --- 5. Compte de service -------------------------------------------
$svcuser = $DB->get_record('user', ['username' => 'svc-n8n', 'mnethostid' => $CFG->mnet_localhost_id]);
if (!$svcuser) {
    $newuser = (object) [
        'username'  => 'svc-n8n',
        'auth'      => 'webservice',
        'email'     => 'svc-n8n@cr465.test',
        'firstname' => 'Service',
        'lastname'  => 'n8n',
        'confirmed' => 1,
        'mnethostid' => $CFG->mnet_localhost_id,
        'lang'      => 'fr',
    ];
    $userid = user_create_user($newuser, false, false);
    $svcuser = $DB->get_record('user', ['id' => $userid]);
    mtrace('Compte de service "svc-n8n" cree');
} else {
    // corriger une eventuelle ancienne valeur (nologin refuse par l'API)
    if ($svcuser->auth !== 'webservice') {
        $DB->set_field('user', 'auth', 'webservice', ['id' => $svcuser->id]);
        mtrace('Auth du compte de service corrigee en "webservice"');
    }
    mtrace('Compte de service "svc-n8n" deja present');
}
role_assign($roleid, $svcuser->id, $systemcontext->id);

// --- 6. Jeton permanent ---------------------------------------------
$DB->delete_records('external_tokens', [
    'userid'            => $svcuser->id,
    'externalserviceid' => $service->id,
]);
$token = bin2hex(random_bytes(16));
$DB->insert_record('external_tokens', (object) [
    'token'             => $token,
    'tokentype'         => 0,          // 0 = permanent
    'userid'            => $svcuser->id,
    'externalserviceid' => $service->id,
    'contextid'         => $systemcontext->id,
    'creatorid'         => $admin->id,
    'iprestriction'     => null,
    'validuntil'        => 0,
    'timecreated'       => time(),
    'lastaccess'        => null,
    'name'              => 'n8n integration',
]);

mtrace('Service : cr465 (id=' . $service->id . ')');
mtrace('Utilisateur : svc-n8n (id=' . $svcuser->id . ')');
mtrace('Role : servicen8n (id=' . $roleid . ')');
mtrace('TOKEN=' . $token);
