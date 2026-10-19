<?php
// ============================================================
// CR465 - Cree le cours de demonstration s'il n'existe pas.
// A executer DANS le conteneur Moodle : php /tmp/seed-course.php
// Idempotent.
// ============================================================

define('CLI_SCRIPT', true);
require('/var/www/html/public/config.php');
require_once($CFG->dirroot . '/course/lib.php');

$admin = get_admin();
\core\session\manager::set_user($admin);

$shortname = 'CR465-DEMO';
$existing = $DB->get_record('course', ['shortname' => $shortname]);

// Active l'inscription manuelle sur un cours (idempotent).
function activate_manual_enrol($courseid) {
    global $DB;
    $enrol = enrol_get_plugin('manual');
    $instance = $DB->get_record('enrol', ['courseid' => $courseid, 'enrol' => 'manual']);
    if ($instance && (int) $instance->status !== ENROL_INSTANCE_ENABLED) {
        $enrol->update_status($instance, ENROL_INSTANCE_ENABLED);
        mtrace('Inscription manuelle activee sur le cours ' . $courseid);
    }
}

if ($existing) {
    mtrace('Cours deja present : ' . $shortname . ' (id=' . $existing->id . ')');
    activate_manual_enrol($existing->id);
    exit(0);
}

$category = $DB->get_record('course_categories', ['name' => 'CR465']);
if (!$category) {
    $catid = $DB->insert_record('course_categories', (object) [
        'name'        => 'CR465',
        'idnumber'    => 'CR465',
        'description' => 'Formations de la plateforme CR465',
        'parent'      => 0,
        'sortorder'   => 1,
        'visible'     => 1,
        'timecreated' => time(),
        'timemodified' => time(),
    ]);
    $category = $DB->get_record('course_categories', ['id' => $catid]);
    mtrace('Categorie "CR465" creee');
}

$course = (object) [
    'fullname'    => 'Formation CR465 - Demonstration',
    'shortname'   => $shortname,
    'category'    => $category->id,
    'summary'     => 'Cours cree automatiquement pour demontrer l attribution d acces apres achat.',
    'format'      => 'topics',
    'visible'     => 1,
    'numsections' => 3,
];
$created = create_course($course);
mtrace('Cours cree : id=' . $created->id . ' shortname=' . $created->shortname);

// Activer l'inscription manuelle : sans cela, enrol_manual_enrol_users
// ne fait rien (l'instance d'inscription est desactivee par defaut).
$enrol = enrol_get_plugin('manual');
$instance = $DB->get_record('enrol', ['courseid' => $created->id, 'enrol' => 'manual']);
if ($instance && (int) $instance->status !== ENROL_INSTANCE_ENABLED) {
    $enrol->update_status($instance, ENROL_INSTANCE_ENABLED);
    mtrace('Inscription manuelle activee sur le cours');
}
