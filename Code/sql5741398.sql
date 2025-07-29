-- phpMyAdmin SQL Dump
-- version 4.7.1
-- https://www.phpmyadmin.net/
--
-- Host: sql5.freesqldatabase.com
-- Generation Time: Dec 02, 2024 at 07:26 PM
-- Server version: 5.5.62-0ubuntu0.14.04.1
-- PHP Version: 7.0.33-0ubuntu0.16.04.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sql5741398`
--

DELIMITER $$
--
-- Procedures
--
CREATE  PROCEDURE `check_and_add_modules` (IN `student_id` INT, IN `p_semester` INT, IN `academic_year` VARCHAR(10), IN `module_ids` VARCHAR(255))  BEGIN
    DECLARE total_credits INT DEFAULT 0;
    DECLARE module_exists BOOLEAN DEFAULT FALSE;

    -- Check if the student has already enrolled in modules for the specified semester and academic year
    SELECT COUNT(*) > 0 INTO module_exists
    FROM enroll
    WHERE stdID = student_id 
      AND semester = p_semester 
      AND year = academic_year;

    -- If modules already exist for the specified semester and academic year, block insertion
    IF module_exists THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Modules already exist for the specified semester and academic year. Cannot add more modules.';
    END IF;

    -- Calculate the total credits of the provided module IDs
    SELECT SUM(num_of_credits) INTO total_credits
    FROM module
    WHERE FIND_IN_SET(moduleID, module_ids);

    -- Check if total credits are between 9 and 21
    IF total_credits < 9 OR total_credits > 21 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total module credits must be between 9 and 21.';
    END IF;

    -- Insert modules into the enroll table (if no existing enrollment)
    INSERT INTO enroll (stdID, moduleID, semester, year)
    SELECT student_id, moduleID, p_semester, academic_year
    FROM module
    WHERE FIND_IN_SET(moduleID, module_ids);

END$$

CREATE  PROCEDURE `GetStudentGradesAndCredits` (IN `studentID` VARCHAR(20), IN `academicYear` VARCHAR(10))  BEGIN
    -- Check if the student exists
    IF NOT EXISTS (SELECT 1 FROM student WHERE stdID = studentID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student does not exist.';
    END IF;

    -- Check if the student has enrolled in any modules in the specified academic year
    IF NOT EXISTS (
        SELECT 1 
        FROM enroll 
        WHERE stdID = studentID AND year = academicYear
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No modules found for the student in the specified academic year.';
    END IF;

    -- Check if the student has grades entered for all modules in the specified academic year
    IF EXISTS (
        SELECT 1 
        FROM enroll e
        JOIN module m ON e.moduleID = m.moduleID
        WHERE e.stdID = studentID 
        AND e.year = academicYear
        AND e.grade IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not all grades are entered for the student in the specified academic year.';
    END IF;

    -- Retrieve the grades and credits if checks pass
    SELECT 
        e.semester,
        e.grade,
        m.num_of_credits
    FROM 
        enroll e
    JOIN 
        module m ON e.moduleID = m.moduleID
    WHERE 
        e.stdID = studentID
        AND e.year = academicYear
    ORDER BY 
        e.semester, e.moduleID;

END$$

CREATE  PROCEDURE `get_student_grades_for_semester` (IN `student_id` INT, IN `year` VARCHAR(10), IN `semester` INT)  BEGIN
    DECLARE student_exists INT;

    -- Check if the student exists
    SELECT COUNT(*) INTO student_exists
    FROM student
    WHERE stdID = student_id;

    IF student_exists = 0 THEN
        -- If the student does not exist, raise an error or return a message
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not found';
    ELSE
        -- Fetch the grades if the student exists
        SELECT e.moduleID, m.moduleName, e.grade
        FROM enroll e
        JOIN module m ON e.moduleID = m.moduleID
        WHERE e.stdID = student_id AND e.year = year AND e.semester = semester;
    END IF;
END$$

CREATE  PROCEDURE `InsertStudentAndAlert` (IN `fullname` VARCHAR(100), IN `email` VARCHAR(255), IN `password` VARCHAR(100), IN `school` VARCHAR(100), IN `programme` VARCHAR(255), IN `advisor_name` VARCHAR(100), IN `advisor_email` VARCHAR(255), IN `prog_dir_name` VARCHAR(100), IN `prog_dir_email` VARCHAR(255), IN `fac_admin_name` VARCHAR(100), IN `fac_admin_email` VARCHAR(255))  BEGIN
    DECLARE new_stdID INT;

    -- Insert the student record
    INSERT INTO student (full_name, email_address, password, school, programme)
    VALUES (fullname, email, password, school, programme);

    -- Get the last inserted stdID
    SET new_stdID = LAST_INSERT_ID();

    -- Insert the alert record
    INSERT INTO alert (stdID, faculty_admin_email, faculty_admin_name, advisor_name, advisor_email, prog_dir_name, prog_dir_email)
    VALUES (new_stdID, fac_admin_email, fac_admin_name, advisor_name, advisor_email, prog_dir_name, prog_dir_email);
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `adminID` varchar(20) NOT NULL,
  `admin_fullname` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`adminID`, `admin_fullname`, `password`) VALUES
('adm1', 'John Doe', 'P@ssw0rd1'),
('adm2', 'Jane Smith', 'P@ssw0rd2'),
('adm3', 'Emily Johnson', 'P@ssw0rd3'),
('adm4', 'Michael Williams', 'P@ssw0rd4'),
('adm5', 'Sarah Brown', 'P@ssw0rd5');

-- --------------------------------------------------------

--
-- Table structure for table `alert`
--

CREATE TABLE `alert` (
  `stdID` int(11) NOT NULL,
  `faculty_admin_email` varchar(255) NOT NULL,
  `faculty_admin_name` varchar(100) NOT NULL,
  `advisor_name` varchar(100) NOT NULL,
  `advisor_email` varchar(255) NOT NULL,
  `prog_dir_name` varchar(100) NOT NULL,
  `prog_dir_email` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `alert`
--

INSERT INTO `alert` (`stdID`, `faculty_admin_email`, `faculty_admin_name`, `advisor_name`, `advisor_email`, `prog_dir_name`, `prog_dir_email`) VALUES
(2400026, 'davistyoni13@gmail.com', 'Tyoni Davis', 'Dwayne Gibbs', 'dwaynelgibbs@gmail.com', 'Kemar Christie', 'kemarchristie15@gmail.com');

-- --------------------------------------------------------

--
-- Table structure for table `enroll`
--

CREATE TABLE `enroll` (
  `stdID` int(11) NOT NULL,
  `moduleID` varchar(20) NOT NULL,
  `semester` int(11) NOT NULL DEFAULT '0',
  `year` varchar(10) NOT NULL DEFAULT '',
  `grade` varchar(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `enroll`
--

INSERT INTO `enroll` (`stdID`, `moduleID`, `semester`, `year`, `grade`) VALUES
(2400026, 'BIO3004', 1, '2024/2025', '55'),
(2400026, 'CIT2004', 1, '2024/2025', '88'),
(2400026, 'CIT3003', 1, '2024/2025', '75'),
(2400026, 'CIT3027', 1, '2024/2025', '89'),
(2400026, 'CMP4011', 2, '2024/2025', '90'),
(2400026, 'PHS1019', 2, '2024/2025', '83'),
(2400026, 'STA2016', 2, '2024/2025', '50'),
(2400026, 'STA2020', 2, '2024/2025', '87');

-- --------------------------------------------------------

--
-- Table structure for table `module`
--

CREATE TABLE `module` (
  `moduleID` varchar(20) NOT NULL,
  `moduleName` varchar(255) DEFAULT NULL,
  `num_of_credits` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `module`
--

INSERT INTO `module` (`moduleID`, `moduleName`, `num_of_credits`) VALUES
('BIO3004', 'Introduction to Bioinformatics', 3),
('CIT2004', 'Object Oriented Programming', 4),
('CIT2011', 'Web Programming', 3),
('CIT3002', 'Operating Systems', 3),
('CIT3003', 'Analysis of Algorithms', 3),
('CIT3006', 'Theory of Computation', 3),
('CIT3009', 'Advanced Programming', 3),
('CIT3012', 'Advanced Databases', 4),
('CIT3013', 'Database Administration', 4),
('CIT3014', 'Advanced Computer Networks', 4),
('CIT3015', 'Digital Communication/ Telecommunication', 4),
('CIT3017', 'Network Administration & Technical Support', 4),
('CIT3018', 'Computer Animation', 4),
('CIT3020', 'Digital Video Effects', 4),
('CIT3021', 'Foundations of Information Systems', 3),
('CIT3023', 'Introduction to Human Computer Interaction', 4),
('CIT3024', 'Enterprise Architecture and Infrastructure', 4),
('CIT3025', 'IS Innovation and Emerging Technologies', 4),
('CIT3027', 'Mobile Computing', 4),
('CIT3029', 'Internship (OPTIONAL)', 4),
('CIT4001', 'Software Implementation', 3),
('CIT4004', 'Analysis of Programming Languages', 3),
('CIT4009', 'Enterprise Computing 1', 4),
('CIT4011', 'Digital Graphics', 4),
('CIT4017', 'Decision Science', 3),
('CIT4020', 'Computer Security', 3),
('CIT4023', 'E-Business Strategy & E-Commerce', 4),
('CIT4024', 'IT Project Management', 4),
('CIT4031', 'IS Auditing', 4),
('CIT4032', 'IS Strategy, Planning and Management', 4),
('CIT4033', 'Distributed Systems', 4),
('CIT4034', 'Web Systems Design & Implementation', 4),
('CIT4035', 'Network Management and Security', 4),
('CIT4036', 'Professional Development Seminar', 1),
('CMP1005', 'Computer Logic & Digital Design', 3),
('CMP1024', 'Programming 1', 4),
('CMP1026', 'Computer Networks 1', 3),
('CMP2006', 'Data Structures', 4),
('CMP2018', 'Database Design', 3),
('CMP2019', 'Software Engineering Analysis & Design', 3),
('CMP3011', 'Computer Organisation and Assembly', 3),
('CMP3040', 'Forensic Computing', 3),
('CMP3041', 'Applied Software Testing', 4),
('CMP4011', 'Artificial Intelligence', 4),
('COM1024', 'Academic Literacy for Undergraduates', 3),
('COM2016', 'Critical Thinking, Reading and Writing', 3),
('CS101', 'Introduction to Computer Science', 3),
('CSP1001', 'Community Service Project', 1),
('ENG150', 'English Composition', 2),
('ENS3001', 'Environmental Studies', 3),
('ENT3001', 'Entrepreneurship', 3),
('HEA3003', 'Fitness & Wellness', 3),
('HIST100', 'World History', 3),
('HUM3010', 'Professional Ethics & Legal Implications of Computing Systems', 3),
('INT1001', 'Information Technology', 3),
('MAT1008', 'Discrete Mathematics', 4),
('MAT1043', 'Linear Algebra', 3),
('MAT1047', 'College Mathematics 1B', 4),
('MAT2003', 'Calculus 1', 3),
('MATH202', 'Calculus II', 4),
('MEE2003', 'Material Science', 3),
('PHS1019', 'Physics for Computer Science', 4),
('PRJ4020', 'Major Project', 3),
('PSY1002', 'Introduction to Psychology', 3),
('RES3024', 'Computing Research Methods', 3),
('STA2016', 'Design of Experiments', 3),
('STA2020', 'Introductory Statistics', 3);

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

CREATE TABLE `student` (
  `stdID` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL,
  `email_address` varchar(255) NOT NULL,
  `school` varchar(100) DEFAULT NULL,
  `programme` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `student`
--

INSERT INTO `student` (`stdID`, `full_name`, `password`, `email_address`, `school`, `programme`) VALUES
(2400026, 'Kyle Willis', 'Kyl3Will', 'Kwillis@mail.com', 'SCIT', 'Bsc. in Computing');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`adminID`);

--
-- Indexes for table `alert`
--
ALTER TABLE `alert`
  ADD PRIMARY KEY (`stdID`);

--
-- Indexes for table `enroll`
--
ALTER TABLE `enroll`
  ADD PRIMARY KEY (`stdID`,`moduleID`,`semester`,`year`),
  ADD KEY `moduleID` (`moduleID`);

--
-- Indexes for table `module`
--
ALTER TABLE `module`
  ADD PRIMARY KEY (`moduleID`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`stdID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `student`
--
ALTER TABLE `student`
  MODIFY `stdID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2400027;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `alert`
--
ALTER TABLE `alert`
  ADD CONSTRAINT `alert_ibfk_1` FOREIGN KEY (`stdID`) REFERENCES `student` (`stdID`);

--
-- Constraints for table `enroll`
--
ALTER TABLE `enroll`
  ADD CONSTRAINT `enroll_ibfk_1` FOREIGN KEY (`stdID`) REFERENCES `student` (`stdID`),
  ADD CONSTRAINT `enroll_ibfk_2` FOREIGN KEY (`moduleID`) REFERENCES `module` (`moduleID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
