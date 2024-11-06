# create a user
# Create USER username@ip IDENTIFIED BY password;
# CREATE USER 'vua'@'10.100.32.144' IDENTIFIED BY 'mypass'

# Add permission
# GRANT permission ON database.table TO username@ip
# GRANT SELECT ON university.department TO 'vua'@'10.100.32.144';
# GRANT SELECT ON university.* TO 'vua'@'%';

# permissions -> create, alter, drop, insert, update, delete, select, create user
use university;

select *
from university.department;


INSERT INTO department(dept_name, building, budget)
values('','gaziBuilding',97394839);

# Create roles
CREATE ROLE st;

# Grant select for classroom and instructor to student
GRANT SELECT ON university.classroom TO  student;

# View
CREATE VIEW faculty AS
    SELECT instructor.ID, instructor.name, instructor.dept_name
    FROM instructor;

# Index
SELECT *
FROM student
WHERE dept_name = 'Physics';

CREATE INDEX student_indx ON student(dept_name);

SELECT *
FROM department
WHERE building = 'Palmer';

CREATE INDEX department_indx ON department(building);

# User-made Functions
# Takes a department name as input and returns number of teachers in that department
CREATE FUNCTION dept_count(dept_name VARCHAR(20)) RETURNS INTEGER
BEGIN
    DECLARE d_count INTEGER;
    SELECT count(*) INTO d_count
    FROM instructor
    WHERE instructor.dept_name = dept_name;
    RETURN d_count;
end;

# Function
SELECT dept_name, dept_count(dept_name)
FROM department;

CREATE FUNCTION duration(time_slot_id VARCHAR(4)) RETURNS INTEGER
BEGIN
    DECLARE minutes INTEGER;
    SELECT ((end_hr - start_hr) *60 + (end_min - start_min)) INTO minutes
    FROM time_slot
    WHERE time_slot.time_slot_id = time_slot_id;
    RETURN minutes;
END;

SELECT time_slot_id, duration(time_slot_id)
FROM time_slot;

# User-made procedures
DROP PROCEDURE duration_proc;
CREATE PROCEDURE duration_proc(IN time_slot_id VARCHAR(20), OUT minutes INTEGER)
BEGIN
    SELECT ((time_slot.end_hr - time_slot.start_hr) * 60 + (time_slot.end_min - time_slot.start_min)) INTO minutes
    FROM time_slot
    WHERE time_slot.time_slot_id = time_slot_id;
end;

CALL duration_proc('A', @minutes);

SELECT @pi;

SET @pi=3.14;

# Triggers
-- Create a trigger that add credits to tot_credit when he passes a course
CREATE TRIGGER add_credits AFTER INSERT ON takes
FOR EACH ROW
BEGIN
    IF (NEW.grade <> 'F' AND NEW.grade IS NOT NULL) THEN
        UPDATE student
        SET tot_cred = tot_cred + (
            SELECT course.credits FROM course WHERE course.course_id = NEW.course_id
            )
        WHERE student.ID = NEW.ID;
    end if;
end;

CREATE TRIGGER update_credits AFTER UPDATE ON takes
FOR EACH ROW
BEGIN
    IF (NEW.grade <> 'F' AND NEW.grade IS NOT NULL) AND (OLD.grade = 'F' OR OLD.grade IS NULL) THEN
        UPDATE student
        SET tot_cred = tot_cred + (
            SELECT course.credits FROM course WHERE course.course_id = NEW.course_id
            )
        WHERE student.ID = NEW.ID;
    end if;
end;

# Recursive Query
WITH RECURSIVE prereq_rec AS (
    SELECT course_id, prereq_id
    FROM prereq
    UNION
    SELECT prereq.prereq_id, prereq_rec.course_id
    FROM prereq JOIN prereq_rec ON prereq.course_id = prereq_rec.prereq_id
)

SELECT *
FROM prereq_rec;

USE university;
# Write a query that shows the name and department of all students in the university
SELECT name, dept_name
FROM student;
# Write a query that shows the classrooms in the Watson department with a capacity less than 40
SELECT room_number
FROM classroom
WHERE building = 'Watson' AND capacity < 40;
# Write a query that shows the name of all teachers earning a salary between 50000 and 70000
# (using between)
SELECT name
FROM instructor
WHERE salary BETWEEN 50000 AND 70000;
# Find the ID of the teachers that have taken courses in both Fall 2017 and Spring 2018
SELECT ID
FROM takes # Error!!!
WHERE semester = 'Fall' AND year = 2017 AND semester = 'Spring' AND year = 2018;

SELECT ID
FROM teaches
WHERE (semester='Fall' AND year=2017)
AND ID IN (
    SELECT ID
    FROM teaches
    WHERE semester='Spring' AND year=2018
);
# Find the name of the department in the Taylor building with the highest budget
SELECT dept_name
FROM department
WHERE building = 'Taylor'
ORDER BY budget DESC
LIMIT 1;

SELECT dept_name
FROM department
WHERE building = 'Taylor'
AND budget = (
    SELECT MAX(budget)
    FROM department
    WHERE building = 'Taylor'
    );
# Write a query that shows the number of students in each department
SELECT dept_name, COUNT(ID) AS number_of_students
FROM student
GROUP BY dept_name;
# Write a query that shows the average class duration in the university
SELECT AVG((end_hr - time_slot.start_hr)*60 + (end_min - time_slot.start_min)) AS avg_duration
FROM time_slot;

SELECT avg((end_hr * 60 + end_min) - (start_hr * 60 + start_min)) AS duration
FROM time_slot;
# Find the names of all courses in the 300 level
SELECT course.course_id, title
FROM course
WHERE course_id LIKE '%-3__';
# Find out the teachers that have taken at least one course in the Music department
SELECT ID
FROM teaches
WHERE EXISTS(
    SELECT course_id
    FROM course
    WHERE teaches.course_id = course.course_id
    AND dept_name = 'Music'
);

SELECT name
FROM student
WHERE ID IN (
    SELECT ID
    FROM takes
    WHERE grade IS NULL
    );
# Show the names of students who have got no F in any course
SELECT name
FROM student
WHERE NOT EXISTS(
    SELECT *
    FROM takes
    WHERE student.ID = takes.ID
    AND grade = 'F'
);
# Show the names of students who have taken retakes
WITH courses_per_student AS (
    SELECT ID, COUNT(course_id) AS courses
    FROM takes
    GROUP BY ID, course_id
)
SELECT student.name
FROM student
WHERE ID IN (
    SELECT ID
    FROM courses_per_student
    WHERE courses >= 2
    );
# Show the course title of courses which have sections which take longer than 1 hour
SELECT course.title
FROM course
WHERE EXISTS(
    SELECT course_id, section.sec_id, section.semester, section.year
    FROM section
    WHERE course.course_id = section.course_id AND time_slot_id IN (
        SELECT time_slot_id
        FROM time_slot
        WHERE ((end_hr*60 + time_slot.end_min) - (start_hr*60 + time_slot.start_min)) > 60
        )
);
# Show the names of instructors from the biology department that have taken no courses in the
# Comp. Sci. department
SELECT instructor.name
FROM instructor
WHERE dept_name = 'Biology' AND instructor.ID NOT IN(
    SELECT ID
    FROM teaches
    WHERE course_id IN (
        SELECT course_id
        FROM course
        WHERE course.dept_name = 'Comp. Sci.'
        )
    );
# Show a list of names of sections and the capacity of those sections
SELECT section.course_id,sec_id,semester,year, classroom.capacity
FROM section LEFT JOIN classroom USING (building, room_number);
# Show a list of names of sections that take place on Monday
SELECT course_id, sec_id, semester, year
FROM section LEFT JOIN time_slot USING (time_slot_id)
WHERE day = 'M';
# Show a list of courses and the number of sections in each course
SELECT course_id, title, COUNT(sec_id) AS sections
FROM course LEFT JOIN section USING (course_id)
GROUP BY course_id, title, semester, year;
# Show the names of students and the names of their advisor. If no advisor has been assigned to a
# student, show null instead of the advisor’s name
SELECT student.name, instructor.name
FROM (student LEFT JOIN advisor ON student.ID = advisor.s_ID) LEFT JOIN instructor ON instructor.ID = s_ID;
# Display a list of student names and the highest grade they have received in Spring 2018. If a
# student has not received the highest grade, show null
WITH stu_grades AS (
    SELECT takes.ID, student.name, takes.semester, takes.year, takes.grade
    FROM takes NATURAL LEFT JOIN student
), stu_gpa AS (
    SELECT ID, name, semester, year, grade,
    CASE
        WHEN grade = 'A' THEN 4
        WHEN grade = 'A-' THEN 3.66
        WHEN grade = 'B+' THEN 3.33
        WHEN grade = 'B' THEN 3
        WHEN grade = 'B-' THEN 2.66
        WHEN grade = 'C+' THEN 2.33
        WHEN grade = 'C' THEN 2
        WHEN grade = 'F' THEN 0
    END AS gpa
    FROM stu_grades),
    stu_max_gpa AS (
        SELECT ID, name, MAX(gpa) AS max_gpa
        FROM stu_gpa
        WHERE semester = 'Spring' AND year = 2018
        GROUP BY ID, name
    )
SELECT name,
       CASE


        WHEN max_gpa = 4 THEN 'A'
           WHEN max_gpa = 3.66 THEN 'A-'
        WHEN max_gpa = 3.33 THEN 'B+'
           WHEN max_gpa = 3 THEN 'B'
        WHEN max_gpa = 2.66 THEN 'B-'
           WHEN max_gpa = 2.33 THEN 'C+'
        WHEN max_gpa = 2 THEN 'C'
            WHEN max_gpa = 0 THEN 'F'
        END AS max_grade
FROM stu_max_gpa;

# List the names of those students who have not taken any courses
SELECT name
FROM student NATURAL LEFT JOIN takes
WHERE course_id IS NULL;
# Display a list of all instructors, showing each instructor’s name and the number of sections
# taught
SELECT name, count(course_id) AS courses
FROM instructor NATURAL LEFT JOIN teaches
GROUP BY id, name;
# List the names of students along with the titles of courses that they have taken
SELECT student.name, course.title
FROM student LEFT JOIN takes ON student.ID = takes.ID LEFT JOIN section ON
takes.course_id = section.course_id AND takes.sec_id = section.sec_id AND
takes.semester = section.semester AND takes.year = section.year JOIN
course ON section.course_id = course.course_id;
# Show a table that contains names of students, the course name of the sections that they take
# and the instructor that takes that section
SELECT student.name, course.title, instructor.name
FROM (student LEFT JOIN takes ON student.ID = takes.ID LEFT JOIN section
ON section.course_id = takes.course_id AND section.sec_id = takes.sec_id
AND section.semester = takes.semester AND section.year = takes.year LEFT
JOIN course ON section.course_id = course.course_id) JOIN teaches ON
section.course_id = teaches.course_id = section.course_id AND
teaches.sec_id = section.sec_id AND teaches.semester = section.semester
AND teaches.year = section.year JOIN instructor ON teaches.ID =
instructor.ID;
# Show the names of instructors from the biology department that have taken no courses in the
# Comp. Sci. department
SELECT DISTINCT instructor.name
FROM instructor LEFT JOIN teaches ON instructor.ID = teaches.ID LEFT JOIN
section ON teaches.course_id = section.course_id AND teaches.sec_id =
section.sec_id AND teaches.semester = section.semester AND teaches.year =
section.year JOIN course ON section.course_id = course.course_id
WHERE instructor.dept_name = 'Biology' AND (course.dept_name <>'Comp.
Sci.' OR course.dept_name IS NULL);
# Show the names of courses and the average duration of sections in that course in the Spring
# 2018 semester
SELECT course.title, AVG((time_slot.end_hr*60+time_slot.end_min)-(time_slot.start_hr*60+time_slot.start_min)) AS avg_duration
FROM course JOIN section USING (course_id) LEFT JOIN time_slot USING (time_slot_id)
WHERE semester = 'Spring' AND year = 2018
GROUP BY course_id, title;
# Show the names of students who have got no F in any course
SELECT DISTINCT student.name
FROM student LEFT JOIN takes USING (ID)
WHERE takes.grade<> 'F';
# Show the names of students who have taken retakes
WITH courses_per_student AS (
    SELECT takes.ID, COUNT(takes.course_id) AS courses
    FROM takes
    GROUP BY ID, course_id
)
SELECT student.name
FROM student
WHERE ID IN (
    SELECT ID
    FROM courses_per_student
    WHERE courses >= 2
    );

SELECT name
FROM student NATURAL LEFT JOIN takes
GROUP BY ID, name, course_id
HAVING COUNT(course_id) > 1;
