CREATE DATABASE  IF NOT EXISTS `warp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `warp`;
-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: warp
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `user_accounts`
--

DROP TABLE IF EXISTS `user_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `display_name` varchar(45) NOT NULL,
  `username` varchar(45) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `height_meter` decimal(5,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_accounts`
--

LOCK TABLES `user_accounts` WRITE;
/*!40000 ALTER TABLE `user_accounts` DISABLE KEYS */;
INSERT INTO `user_accounts` VALUES (1,'John Doe','johndoe','$argon2id$v=19$m=19,t=2,p=1$VVdLeERYRjdSMmtkbFNuRg$K71wnUpop7rsK+AVsN/8hw',1.80),(2,'Jane Doe','janedoe','$argon2id$v=19$m=19,t=2,p=1$MVI2aHpmUHpDZjFFTkRkbw$omH5BzjgrJv6LVL7glW8pw',1.60),(3,'Joe Schmo','joeschmo','$argon2id$v=19$m=19,t=2,p=1$WTJ2NWczeVpUaVBwUlpHTw$MQeieYuPf4WOX0/gDJiAMg',1.70),(4,'A. N. Other','another','$argon2id$v=19$m=19,t=2,p=1$dkdDMU5qME1yQTNUN1k2aA$gjPCKRHt1OMHryvQIAYIhQ',1.75),(5,'Alan Smithee','alansmithee','$argon2id$v=19$m=19,t=2,p=1$OVhkcEVSNEJCbmhMSDV3Uw$R725dalnKuDAtbgI1X5xLQ',1.78),(6,'Alice','alice','$argon2id$v=19$m=19,t=2,p=1$OVRQV3g2eElOTHlxbnZvbA$ufFznXuE0gWtU0actuGrCQ',1.50),(7,'Bob','bob','$argon2id$v=19$m=19,t=2,p=1$OEVRdGhZTnhwdGNsMVRsdw$dQsby834BGI3rxnr64OCkw',1.67),(8,'Charlie','charlie','$argon2id$v=19$m=19,t=2,p=1$M1ZORjdoSkFYb2N1V01HYg$7GUFoJCKXEPs5qCnTYssnA',1.74),(9,'Trudy','trudy','$argon2id$v=19$m=19,t=2,p=1$WHJnSzVvb0lPZm9DUmlEZw$gz95aS02OnU1rPAMOP57NA',1.62),(10,'Cissia','cissia','$argon2id$v=19$m=19,t=2,p=1$WFVYNmhvTXhDTmt2Z2luVA$x3j16o/prugbVygnHYcTdw',1.60);
/*!40000 ALTER TABLE `user_accounts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-17 17:45:11
