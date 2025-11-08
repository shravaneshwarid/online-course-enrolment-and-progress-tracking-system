CREATE DATABASE OnlineCourseDB;
USE OnlineCourseDB;

CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role ENUM('student','instructor','admin') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    instructor_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES Users(user_id)
);

CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    date_enrolled DATE DEFAULT (CURRENT_DATE),
    status ENUM('active','completed','dropped') DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id),
    UNIQUE (user_id, course_id)
);

CREATE TABLE Progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    enrollment_id INT NOT NULL,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    score DECIMAL(5,2) DEFAULT 0.00,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(enrollment_id)
);

INSERT INTO Users (name, email, role) VALUES
('Alice Johnson', 'alice@example.com', 'student'),
('Bob Martin', 'bob@example.com', 'student'),
('Dr. Smith', 'smith@example.com', 'instructor'),
('Admin User', 'admin@example.com', 'admin');

INSERT INTO Courses (title, description, instructor_id) VALUES
('SQL for Beginners', 'Learn the basics of SQL and relational databases.', 3),
('Advanced DBMS', 'Covers normalization and indexing in depth.', 3);

INSERT INTO Enrollments (user_id, course_id, status) VALUES
(1, 1, 'active'),
(2, 1, 'completed'),
(1, 2, 'active');

INSERT INTO Progress (enrollment_id, completion_percentage, score) VALUES
(1, 40.00, 70.00),
(2, 100.00, 88.00),
(3, 30.00, 60.00);

DELIMITER $$

CREATE PROCEDURE sp_enroll_student(IN p_user_id INT, IN p_course_id INT)
BEGIN
    DECLARE existing INT;
    SELECT COUNT(*) INTO existing 
    FROM Enrollments WHERE user_id = p_user_id AND course_id = p_course_id;

    IF existing = 0 THEN
        INSERT INTO Enrollments (user_id, course_id, status)
        VALUES (p_user_id, p_course_id, 'active');
    ELSE
        SELECT 'Student already enrolled in this course.' AS message;
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_update_progress(
    IN p_enrollment_id INT,
    IN p_completion DECIMAL(5,2),
    IN p_score DECIMAL(5,2)
)
BEGIN
    UPDATE Progress
    SET completion_percentage = p_completion,
        score = p_score,
        last_updated = NOW()
    WHERE enrollment_id = p_enrollment_id;

    -- Mark enrollment completed if progress = 100%
    IF p_completion = 100.00 THEN
        UPDATE Enrollments
        SET status = 'completed'
        WHERE enrollment_id = p_enrollment_id;
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_generate_report(IN p_user_id INT)
BEGIN
    SELECT 
        u.name AS student_name,
        c.title AS course_title,
        e.status,
        p.completion_percentage,
        p.score
    FROM Users u
    JOIN Enrollments e ON u.user_id = e.user_id
    JOIN Courses c ON c.course_id = e.course_id
    JOIN Progress p ON e.enrollment_id = p.enrollment_id
    WHERE u.user_id = p_user_id;
END $$

DELIMITER ;

CREATE OR REPLACE VIEW v_avg_score_per_student AS
SELECT 
    u.name AS student_name,
    ROUND(AVG(p.score),2) AS avg_score
FROM Users u
JOIN Enrollments e ON u.user_id = e.user_id
JOIN Progress p ON e.enrollment_id = p.enrollment_id
WHERE u.role = 'student'
GROUP BY u.name;

CREATE OR REPLACE VIEW v_course_completion_report AS
SELECT 
    c.title AS course_title,
    COUNT(e.enrollment_id) AS total_students,
    SUM(e.status='completed') AS completed_students,
    ROUND(SUM(e.status='completed') / COUNT(e.enrollment_id) * 100, 2) AS completion_rate
FROM Courses c
LEFT JOIN Enrollments e ON c.course_id = e.course_id
GROUP BY c.title;

CREATE OR REPLACE VIEW v_student_progress AS
SELECT 
    u.name AS student_name,
    c.title AS course_title,
    p.completion_percentage,
    p.score,
    e.status
FROM Users u
JOIN Enrollments e ON u.user_id = e.user_id
JOIN Courses c ON e.course_id = c.course_id
JOIN Progress p ON e.enrollment_id = p.enrollment_id
ORDER BY u.name, c.title;

-- Enroll new student in course 2
CALL sp_enroll_student(2, 2);

-- Update progress for enrollment_id = 1
CALL sp_update_progress(1, 75.00, 80.00);

-- Generate report for student with ID = 1
CALL sp_generate_report(1);

-- View all reports
SELECT * FROM v_avg_score_per_student;
SELECT * FROM v_course_completion_report;
SELECT * FROM v_student_progress;










