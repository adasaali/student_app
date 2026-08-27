<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once '../include/db_connection.php';

function getUserIdFromToken($token) {
    $decoded = base64_decode($token);
    if ($decoded === false) return null;
    $parts = explode('|', $decoded);
    if (count($parts) == 2 && is_numeric($parts[0])) {
        return (int)$parts[0];
    }
    return null;
}

$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? '';
$token = str_replace('Bearer ', '', $authHeader);

if (empty($token)) {
    echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
    exit;
}

$userId = getUserIdFromToken($token);
if (!$userId) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid Token']);
    exit;
}

// ملاحظة: لا يوجد دعم حالياً لـ ?student_id=<اخ> هون (نفس وضع get_absences.php
// حالياً) — الجدول المرجّع هو دائماً جدول صاحب التوكن نفسه. لو حبيت تفعيل
// تبديل الحساب للإخوة هون لاحقاً، لازم تضيف نفس تحقق الأخوّة المستخدم
// أصلاً بـ get_student.php / get_notifications.php قبل ما تسمح بتمرير
// student_id مختلف عن صاحب التوكن.

// جلب صف وشعبة الطالب صاحب التوكن
$stmt = $conn->prepare("SELECT s.grade_id, s.section_id, g.grade_name, sec.section_name
                         FROM students s
                         JOIN grades g ON s.grade_id = g.id
                         JOIN sections sec ON s.section_id = sec.id
                         WHERE s.id = ?
                         LIMIT 1");
$stmt->bind_param('i', $userId);
$stmt->execute();
$student = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$student) {
    echo json_encode(['status' => 'error', 'message' => 'الطالب غير موجود']);
    exit;
}

$sectionId = (int)$student['section_id'];

// الحصص
$periods = [];
$periodsResult = $conn->query("SELECT id, period_number, period_label FROM periods ORDER BY period_number");
while ($row = $periodsResult->fetch_assoc()) {
    $periods[] = [
        'id' => (int)$row['id'],
        'period_number' => (int)$row['period_number'],
        'period_label' => $row['period_label'],
    ];
}

// أسماء الأيام: 0=الأحد ... 4=الخميس (يطابق جدول schedule بالأدمن)
$dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

// خانات الجدول لشعبة الطالب
$sql = "SELECT sc.day_of_week, sc.period_id, sub.name AS subject_name, u.username AS teacher_name
        FROM schedule sc
        JOIN subjects sub ON sc.subject_id = sub.id
        JOIN users u ON sc.teacher_id = u.id
        WHERE sc.section_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $sectionId);
$stmt->execute();
$result = $stmt->get_result();

$cells = [];
while ($row = $result->fetch_assoc()) {
    $key = $row['day_of_week'] . '_' . $row['period_id'];
    $cells[$key] = [
        'subject_name' => $row['subject_name'],
        'teacher_name' => $row['teacher_name'],
    ];
}
$stmt->close();

echo json_encode([
    'status' => 'success',
    'data' => [
        'grade_name' => $student['grade_name'],
        'section_name' => $student['section_name'],
        'periods' => $periods,
        'day_names' => $dayNames,
        'cells' => $cells,
    ],
]);
