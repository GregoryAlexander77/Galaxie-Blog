/*
SQLyog Ultimate - MySQL GUI v8.2
MySQL - 5.1.41-community : Database - myblog_dbo
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/*Table structure for table `tblblogcategories` */

DROP TABLE IF EXISTS `tblblogcategories`;

CREATE TABLE `tblblogcategories` (
  `categoryid` varchar(35) NOT NULL,
  `categoryname` varchar(50) DEFAULT NULL,
  `categoryalias` varchar(50) DEFAULT NULL,
  `blog` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`categoryid`),
  KEY `blogCategories_categoryalias` (`categoryalias`),
  KEY `blogCategories_categoryname` (`categoryname`),
  KEY `blogCategories_blog` (`blog`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Table structure for table `tblblogcomments` */

DROP TABLE IF EXISTS `tblblogcomments`;

CREATE TABLE `tblblogcomments` (
  `id` varchar(35) NOT NULL,
  `entryidfk` varchar(35) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `comment` text,
  `posted` datetime DEFAULT NULL,
  `subscribe` tinyint(1) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `moderated` tinyint(1) DEFAULT NULL,
  `subscribeonly` tinyint(1) DEFAULT NULL,
  `killcomment` varchar(35) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blogComments_entryid` (`entryidfk`),
  KEY `blogComments_posted` (`posted`),
  KEY `blogComments_moderated` (`moderated`),
  KEY `blogComments_email` (`email`),
  KEY `blogComments_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Table structure for table `tblblogentries` */

DROP TABLE IF EXISTS `tblblogentries`;

CREATE TABLE `tblblogentries` (
  `id` varchar(35) CHARACTER SET utf8 NOT NULL,
  `title` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `body` longtext CHARACTER SET utf8,
  `posted` datetime DEFAULT NULL,
  `morebody` longtext CHARACTER SET utf8,
  `alias` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `username` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `blog` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `allowcomments` tinyint(1) DEFAULT NULL,
  `enclosure` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `filesize` int(11) unsigned DEFAULT NULL,
  `mimetype` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `views` int(11) unsigned DEFAULT NULL,
  `released` tinyint(1) DEFAULT NULL,
  `mailed` tinyint(1) DEFAULT NULL,
  `summary` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `subtitle` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `keywords` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `duration` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blogEntries_blog` (`blog`),
  KEY `blogEntries_released` (`released`),
  KEY `blogEntries_posted` (`posted`),
  KEY `blogEntries_title` (`title`),
  KEY `blogEntries_username` (`username`),
  KEY `blogEntries_alias` (`alias`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Table structure for table `tblblogentriescategories` */

DROP TABLE IF EXISTS `tblblogentriescategories`;

CREATE TABLE `tblblogentriescategories` (
  `categoryidfk` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  `entryidfk` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  KEY `blogEntriesCategories_entryidfk` (`entryidfk`,`categoryidfk`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tblblogentriesrelated` */

DROP TABLE IF EXISTS `tblblogentriesrelated`;

CREATE TABLE `tblblogentriesrelated` (
  `entryid` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  `relatedid` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  KEY `blogEntriesRelated_entryid` (`entryid`),
  KEY `blogEntriesRelated_relatedid` (`relatedid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tblblogpages` */

DROP TABLE IF EXISTS `tblblogpages`;

CREATE TABLE `tblblogpages` (
  `id` varchar(35) CHARACTER SET utf8 NOT NULL,
  `blog` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `title` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `alias` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `body` longtext CHARACTER SET utf8,
  `showlayout` tinyint(1) NOT NULL default '0',  
  KEY `blogPages_blog` (`blog`),
  KEY `blogPages_alias` (`alias`),
  KEY `blogPages_title` (`title`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tblblogroles` */

DROP TABLE IF EXISTS `tblblogroles`;

CREATE TABLE `tblblogroles` (
  `id` varchar(35) NOT NULL,
  `role` varchar(50) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blogRoles_role` (`role`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Table structure for table `tblblogsearchstats` */

DROP TABLE IF EXISTS `tblblogsearchstats`;

CREATE TABLE `tblblogsearchstats` (
  `searchterm` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `searched` datetime DEFAULT NULL,
  `blog` varchar(50) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tblblogsubscribers` */

DROP TABLE IF EXISTS `tblblogsubscribers`;

CREATE TABLE `tblblogsubscribers` (
  `email` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `token` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  `blog` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `verified` tinyint(1) DEFAULT NULL,
  KEY `blogSubscribers_blog` (`blog`),
  KEY `blogSubscribers_verified` (`verified`),
  KEY `blogSubscribers_email` (`email`),
  KEY `blogSubscribers_token` (`token`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tblblogtextblocks` */

DROP TABLE IF EXISTS `tblblogtextblocks`;

CREATE TABLE `tblblogtextblocks` (
  `id` varchar(35) CHARACTER SET utf8 DEFAULT NULL,
  `label` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `body` longtext CHARACTER SET utf8,
  `blog` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  KEY `blogTextBlocks_blog` (`blog`),
  KEY `blogTextBlocks_label` (`label`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

/*Table structure for table `tbluserroles` */

DROP TABLE IF EXISTS `tbluserroles`;

CREATE TABLE `tbluserroles` (
  `username` varchar(50) DEFAULT NULL,
  `roleidfk` varchar(35) DEFAULT NULL,
  `blog` varchar(50) DEFAULT NULL,
  KEY `blogUserRoles_blog` (`blog`),
  KEY `blogUserRoles_username` (`username`),
  KEY `blogUserRoles_roleidfk` (`roleidfk`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Table structure for table `tblusers` */

DROP TABLE IF EXISTS `tblusers`;

CREATE TABLE `tblusers` (
  `username` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `password` varchar(256) CHARACTER SET utf8 DEFAULT NULL,
  `salt` varchar(256) CHARACTER SET utf8 DEFAULT NULL,  
  `name` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `blog` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  KEY `blogUsers_username` (`username`),
  KEY `blogUsers_blog` (`blog`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

insert into tblusers(username,password,salt,name,blog) values('admin','74FAE06F4B7BB31F16FA3CB4C873C88FB3669E413603CD103D714CC8C6B153188CEE84D3172F60027D96BAB4A79F275543865C80A927312D5CF00F7DD3F1753A','2XlAbs2fFEESboQCMue3N7yATpwT1QKAFNGIU0hZ35g=','Admin','Default');

/*!40000 ALTER TABLE `tblblogroles` DISABLE KEYS */;
INSERT INTO `tblblogroles` (role,id,description) VALUES  ('AddCategory','7F183B27-FEDE-0D6F-E2E9C35DBC7BFF19','The ability to create a new category when editing a blog entry.'),
 ('ManageCategories','7F197F53-CFF7-18C8-53D0C85FCC2CA3F9','The ability to manage blog categories.'),
 ('Admin','7F25A20B-EE6D-612D-24A7C0CEE6483EC2','A special role for the admin. Allows all functionality.'),
 ('ManageUsers','7F26DA6C-9F03-567F-ACFD34F62FB77199','The ability to manage blog users.'),
 ('ReleaseEntries','800CA7AA-0190-5329-D3C7753A59EA2589','The ability to both release a new entry and edit any released entry.');

INSERT INTO `tbluserroles`(username,roleidfk,blog) VALUES ('admin','7F25A20B-EE6D-612D-24A7C0CEE6483EC2','Default');

CREATE TABLE tblblogpagescategories  (
       categoryidfk    varchar(35) NOT NULL,
       pageidfk        varchar(35) NOT NULL
       )


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
