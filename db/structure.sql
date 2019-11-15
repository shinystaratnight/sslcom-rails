-- MySQL dump 10.13  Distrib 5.7.27, for Linux (x86_64)
--
-- Host: localhost    Database: sandbox_ssl_com
-- ------------------------------------------------------
-- Server version	5.7.27-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `street1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `street2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `region` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `affiliates`
--

DROP TABLE IF EXISTS `affiliates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `affiliates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contact_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tax_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `payout_method` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `payout_threshold` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `payout_frequency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bank_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bank_routing_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `bank_account_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `swift_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `checks_payable_to` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `epassporte_account` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `paypal_account` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type_organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=85 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `api_credentials`
--

DROP TABLE IF EXISTS `api_credentials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `api_credentials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `account_key` varchar(255) DEFAULT NULL,
  `secret_key` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `roles` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_api_credentials_on_account_key_and_secret_key` (`account_key`,`secret_key`),
  KEY `index_api_credentials_on_ssl_account_id` (`ssl_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=474113 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `apis`
--

DROP TABLE IF EXISTS `apis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `apis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=980190963 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `assignments`
--

DROP TABLE IF EXISTS `assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_assignments_on_user_id_and_ssl_account_id_and_role_id` (`user_id`,`ssl_account_id`,`role_id`),
  KEY `index_assignments_on_user_id_and_ssl_account_id` (`user_id`,`ssl_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40440 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `authentications`
--

DROP TABLE IF EXISTS `authentications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `authentications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `nick_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auto_renewals`
--

DROP TABLE IF EXISTS `auto_renewals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auto_renewals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `body` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `recipients` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `billing_profiles`
--

DROP TABLE IF EXISTS `billing_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `billing_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `company` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `credit_card` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `card_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expiration_month` int(11) DEFAULT NULL,
  `expiration_year` int(11) DEFAULT NULL,
  `security_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_digits` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `data` blob,
  `salt` blob,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `encrypted_card_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `encrypted_card_number_salt` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `encrypted_card_number_iv` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `vat` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tax` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `default_profile` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_billing_profile_on_ssl_account_id` (`ssl_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11256 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blocklists`
--

DROP TABLE IF EXISTS `blocklists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocklists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `domain` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `validation` int(11) DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ca_api_requests`
--

DROP TABLE IF EXISTS `ca_api_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ca_api_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `api_requestable_id` int(11) DEFAULT NULL,
  `api_requestable_type` varchar(191) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `request_url` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `parameters` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `method` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `response` mediumtext,
  `type` varchar(191) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ca` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `raw_request` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `request_method` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `username` varchar(255) DEFAULT NULL,
  `approval_id` varchar(255) DEFAULT NULL,
  `certificate_chain` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_ca_api_requests_on_type_and_api_requestable` (`id`,`api_requestable_id`,`api_requestable_type`,`type`),
  UNIQUE KEY `index_ca_api_requests_on_username_and_approval_id` (`username`,`approval_id`),
  KEY `index_ca_api_requests_on_type_and_api_requestable_and_created_at` (`id`,`api_requestable_id`,`api_requestable_type`,`type`,`created_at`),
  KEY `index_ca_api_requests_on_api_requestable` (`api_requestable_id`,`api_requestable_type`),
  KEY `index_ca_api_requests_on_type_and_username` (`type`,`username`)
) ENGINE=InnoDB AUTO_INCREMENT=3472760 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `caa_checks`
--

DROP TABLE IF EXISTS `caa_checks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `caa_checks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `checkable_id` int(11) DEFAULT NULL,
  `checkable_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `domain` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `request` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `result` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cas`
--

DROP TABLE IF EXISTS `cas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `friendly_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `profile_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `algorithm` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `caa_issuers` varchar(255) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `admin_host` varchar(255) DEFAULT NULL,
  `ekus` varchar(255) DEFAULT NULL,
  `end_entity` varchar(255) DEFAULT NULL,
  `ca_name` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `client_cert` varchar(255) DEFAULT NULL,
  `client_key` varchar(255) DEFAULT NULL,
  `client_password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cas_certificates`
--

DROP TABLE IF EXISTS `cas_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cas_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_id` int(11) NOT NULL,
  `ca_id` int(11) NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_cas_certificates_on_certificate_id` (`certificate_id`),
  KEY `index_cas_certificates_on_ca_id` (`ca_id`),
  KEY `index_cas_certificates_on_certificate_id_and_ca_id` (`certificate_id`,`ca_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cdns`
--

DROP TABLE IF EXISTS `cdns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cdns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `api_key` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `resource_id` varchar(255) DEFAULT NULL,
  `custom_domain_name` varchar(255) DEFAULT NULL,
  `certificate_order_id` int(11) DEFAULT NULL,
  `is_ssl_req` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_rails_486d5cc190` (`certificate_order_id`),
  CONSTRAINT `fk_rails_486d5cc190` FOREIGN KEY (`certificate_order_id`) REFERENCES `certificate_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_api_requests`
--

DROP TABLE IF EXISTS `certificate_api_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_api_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_software_id` int(11) DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `account_key` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `secret_key` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `test` tinyint(1) DEFAULT NULL,
  `product` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `period` int(11) DEFAULT NULL,
  `server_count` int(11) DEFAULT NULL,
  `other_domains` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `common_names_flag` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `csr` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `organization_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `post_office_box` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `street_address_1` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `street_address_2` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `street_address_3` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `locality_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `state_or_province_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `duns_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `company_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `registered_locality_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `registered_state_or_province_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `registered_country_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `assumed_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `business_category` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `email_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `contact_email_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `dcv_email_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ca_certificate_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `incorporation_date` date DEFAULT NULL,
  `is_customer_validated` tinyint(1) DEFAULT NULL,
  `hide_certificate_reference` tinyint(1) DEFAULT NULL,
  `external_order_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_order_number_constraint` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `response` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_contents`
--

DROP TABLE IF EXISTS `certificate_contents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_contents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) NOT NULL,
  `signing_request` text COLLATE utf8_unicode_ci,
  `signed_certificate` text COLLATE utf8_unicode_ci,
  `server_software_id` int(11) DEFAULT NULL,
  `domains` text COLLATE utf8_unicode_ci,
  `duration` int(11) DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `billing_checkbox` tinyint(1) DEFAULT NULL,
  `validation_checkbox` tinyint(1) DEFAULT NULL,
  `technical_checkbox` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `agreement` tinyint(1) DEFAULT NULL,
  `ext_customer_ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `approval` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ca_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_certificate_contents_on_certificate_order_id` (`certificate_order_id`),
  KEY `index_certificate_contents_on_workflow_state` (`workflow_state`),
  KEY `index_certificate_contents_on_ref` (`ref`),
  KEY `index_certificate_contents_on_ca_id` (`ca_id`)
) ENGINE=InnoDB AUTO_INCREMENT=75768 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_enrollment_requests`
--

DROP TABLE IF EXISTS `certificate_enrollment_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_enrollment_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_id` int(11) NOT NULL,
  `ssl_account_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `duration` int(11) NOT NULL,
  `domains` text NOT NULL,
  `common_name` text,
  `signing_request` text,
  `server_software_id` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_certificate_enrollment_requests_on_certificate_id` (`certificate_id`),
  KEY `index_certificate_enrollment_requests_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_certificate_enrollment_requests_on_user_id` (`user_id`),
  KEY `index_certificate_enrollment_requests_on_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_lookups`
--

DROP TABLE IF EXISTS `certificate_lookups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_lookups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate` text,
  `serial` varchar(255) DEFAULT NULL,
  `common_name` varchar(255) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `starts_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_names`
--

DROP TABLE IF EXISTS `certificate_names`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_content_id` int(11) DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_common_name` tinyint(1) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `acme_account_id` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  `caa_passed` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_certificate_names_on_certificate_content_id` (`certificate_content_id`),
  KEY `index_certificate_names_on_name` (`name`),
  KEY `index_certificate_names_on_ssl_account_id` (`ssl_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=137911 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_order_domains`
--

DROP TABLE IF EXISTS `certificate_order_domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_order_domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `domain_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_order_managed_csrs`
--

DROP TABLE IF EXISTS `certificate_order_managed_csrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_order_managed_csrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `managed_csr_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_order_tokens`
--

DROP TABLE IF EXISTS `certificate_order_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_order_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `is_expired` tinyint(1) DEFAULT NULL,
  `due_date` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `passed_token` varchar(255) DEFAULT NULL,
  `phone_verification_count` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `phone_call_count` int(11) DEFAULT NULL,
  `phone_number` varchar(255) DEFAULT NULL,
  `callback_type` varchar(255) DEFAULT NULL,
  `callback_timezone` varchar(255) DEFAULT NULL,
  `callback_datetime` datetime DEFAULT NULL,
  `is_callback_done` tinyint(1) DEFAULT NULL,
  `callback_method` varchar(255) DEFAULT NULL,
  `locale` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate_orders`
--

DROP TABLE IF EXISTS `certificate_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `validation_id` int(11) DEFAULT NULL,
  `site_seal_id` int(11) DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `num_domains` int(11) DEFAULT NULL,
  `server_licenses` int(11) DEFAULT NULL,
  `line_item_qty` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_expired` tinyint(1) DEFAULT NULL,
  `renewal_id` int(11) DEFAULT NULL,
  `is_test` tinyint(1) DEFAULT NULL,
  `auto_renew` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `auto_renew_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ca` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `external_order_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ext_customer_ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `validation_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `acme_account_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wildcard_count` int(11) DEFAULT NULL,
  `nonwildcard_count` int(11) DEFAULT NULL,
  `folder_id` int(11) DEFAULT NULL,
  `assignee_id` int(11) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `request_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_certificate_orders_on_workflow_state` (`id`,`workflow_state`,`is_expired`,`is_test`),
  KEY `index_certificate_orders_on_ref` (`ref`),
  KEY `index_certificate_orders_on_created_at` (`created_at`),
  KEY `index_certificate_orders_on_is_expired` (`is_expired`),
  KEY `index_certificate_orders_site_seal_id` (`site_seal_id`),
  KEY `index_certificate_orders_on_test` (`id`,`is_test`),
  KEY `index_certificate_orders_on_is_test` (`is_test`),
  KEY `index_certificate_orders_on_validation_id` (`validation_id`),
  KEY `index_certificate_orders_on_4_cols` (`ssl_account_id`,`workflow_state`,`is_test`,`updated_at`),
  KEY `index_certificate_orders_on_3_cols` (`workflow_state`,`is_expired`,`is_test`),
  KEY `index_certificate_orders_on_id_and_ref_and_ssl_account_id` (`id`,`ref`,`ssl_account_id`),
  KEY `index_certificate_orders_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_certificate_orders_on_ws_ie_it_ua` (`workflow_state`,`is_expired`,`is_test`),
  KEY `index_certificate_orders_on_3_cols(2)` (`ssl_account_id`,`workflow_state`,`id`),
  KEY `index_certificate_orders_on_ws_is_ri` (`workflow_state`,`is_expired`,`renewal_id`),
  KEY `index_certificate_orders_on_ws_ie_ri` (`workflow_state`,`is_expired`,`renewal_id`) USING BTREE,
  KEY `index_certificate_orders_on_workflow_state_and_renewal_id` (`workflow_state`,`renewal_id`) USING BTREE,
  KEY `index_certificate_orders_on_workflow_state_and_is_expired` (`workflow_state`,`is_expired`),
  KEY `index_certificate_orders_on_id_ws_ie_it` (`id`,`workflow_state`,`is_expired`,`is_test`),
  FULLTEXT KEY `index_certificate_orders_r_eon_n` (`ref`,`external_order_number`,`notes`)
) ENGINE=InnoDB AUTO_INCREMENT=62656 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificates`
--

DROP TABLE IF EXISTS `certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reseller_tier_id` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary` text COLLATE utf8_unicode_ci,
  `text_only_summary` text COLLATE utf8_unicode_ci,
  `description` text COLLATE utf8_unicode_ci,
  `text_only_description` text COLLATE utf8_unicode_ci,
  `allow_wildcard_ucc` tinyint(1) DEFAULT NULL,
  `published_as` varchar(16) COLLATE utf8_unicode_ci DEFAULT 'draft',
  `serial` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `icons` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `display_order` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT '--- []',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `special_fields` varchar(255) COLLATE utf8_unicode_ci DEFAULT '--- []',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10151 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificates_products`
--

DROP TABLE IF EXISTS `certificates_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificates_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `client_applications`
--

DROP TABLE IF EXISTS `client_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `client_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `support_url` varchar(255) DEFAULT NULL,
  `callback_url` varchar(255) DEFAULT NULL,
  `key` varchar(40) DEFAULT NULL,
  `secret` varchar(40) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_client_applications_on_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contact_validation_histories`
--

DROP TABLE IF EXISTS `contact_validation_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contact_validation_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contact_id` int(11) NOT NULL,
  `validation_history_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contact_validation_histories_on_contact_id` (`contact_id`),
  KEY `index_contact_validation_histories_on_validation_history_id` (`validation_history_id`),
  KEY `index_cont_val_histories_on_contact_id_and_validation_history_id` (`contact_id`,`validation_history_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `company_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `department` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `po_box` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address3` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ext` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fax` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT '--- []',
  `contactable_id` int(11) DEFAULT NULL,
  `contactable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `registrant_type` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `callback_method` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `incorporation_date` date DEFAULT NULL,
  `incorporation_country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `incorporation_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `incorporation_city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assumed_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `business_category` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `duns_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `company_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `registration_service` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `saved_default` tinyint(1) DEFAULT '0',
  `status` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `special_fields` text COLLATE utf8_unicode_ci,
  `domains` text COLLATE utf8_unicode_ci,
  `country_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_number_approved` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_contacts_on_contactable_id_and_contactable_type` (`contactable_id`,`contactable_type`),
  KEY `index_contacts_on_id_and_parent_id` (`id`,`parent_id`),
  KEY `index_contacts_on_user_id` (`user_id`),
  KEY `index_contacts_on_type_and_contactable_type` (`type`,`contactable_type`),
  FULLTEXT KEY `index_contacts_on_16` (`first_name`,`last_name`,`company_name`,`department`,`po_box`,`address1`,`address2`,`address3`,`city`,`state`,`country`,`postal_code`,`email`,`notes`,`assumed_name`,`duns_number`)
) ENGINE=InnoDB AUTO_INCREMENT=309069 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `countries`
--

DROP TABLE IF EXISTS `countries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `iso1_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name_caps` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `iso3_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `num_code` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1067060302 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `csr_overrides`
--

DROP TABLE IF EXISTS `csr_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `csr_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `common_name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization_unit` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_1` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_2` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_3` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `po_box` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `locality` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `csr_unique_values`
--

DROP TABLE IF EXISTS `csr_unique_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `csr_unique_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unique_value` varchar(255) DEFAULT NULL,
  `csr_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `csrs`
--

DROP TABLE IF EXISTS `csrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `csrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_content_id` int(11) DEFAULT NULL,
  `body` text COLLATE utf8_unicode_ci,
  `duration` int(11) DEFAULT NULL,
  `common_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `sig_alg` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `subject_alternative_names` text COLLATE utf8_unicode_ci,
  `strength` int(11) DEFAULT NULL,
  `challenge_password` tinyint(1) DEFAULT NULL,
  `certificate_lookup_id` int(11) DEFAULT NULL,
  `decoded` text COLLATE utf8_unicode_ci,
  `ext_customer_ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `public_key_sha1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `public_key_sha256` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `public_key_md5` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  `ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `friendly_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modulus` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_csrs_on_common_name` (`common_name`),
  KEY `index_csrs_on_organization` (`organization`),
  KEY `index_csrs_on_common_name_and_certificate_content_id` (`certificate_content_id`,`common_name`),
  KEY `index_csrs_on_certificate_content_id` (`certificate_content_id`),
  KEY `index_csrs_on_sig_alg_and_common_name_and_email` (`sig_alg`,`common_name`,`email`),
  KEY `index_csrs_on_common_name_and_email_and_sig_alg` (`common_name`,`email`,`sig_alg`),
  KEY `index_csrs_on_3_cols` (`common_name`,`email`,`sig_alg`),
  KEY `index_csrs_on_ssl_account_id` (`ssl_account_id`),
  FULLTEXT KEY `index_csrs_cn_b_d` (`common_name`,`body`,`decoded`)
) ENGINE=InnoDB AUTO_INCREMENT=102048 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dbs`
--

DROP TABLE IF EXISTS `dbs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dbs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `host` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `username` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `delayed_job_groups`
--

DROP TABLE IF EXISTS `delayed_job_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `delayed_job_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `on_completion_job` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `on_completion_job_options` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `on_cancellation_job` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `on_cancellation_job_options` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `queueing_complete` tinyint(1) NOT NULL DEFAULT '0',
  `blocked` tinyint(1) NOT NULL DEFAULT '0',
  `failure_cancels_group` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=397 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `delayed_jobs`
--

DROP TABLE IF EXISTS `delayed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` longtext COLLATE utf8_unicode_ci NOT NULL,
  `last_error` longtext COLLATE utf8_unicode_ci,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `queue` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `blocked` tinyint(1) NOT NULL DEFAULT '0',
  `job_group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_delayed_jobs_on_job_group_id` (`job_group_id`),
  KEY `delayed_jobs_queue` (`queue`),
  KEY `index_delayed_jobs_on_priority_and_run_at_and_locked_by` (`priority`,`run_at`,`locked_by`)
) ENGINE=InnoDB AUTO_INCREMENT=182 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `deposits`
--

DROP TABLE IF EXISTS `deposits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deposits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `amount` float DEFAULT NULL,
  `full_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `credit_card` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_digits` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `payment_method` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7745 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discountables_sellables`
--

DROP TABLE IF EXISTS `discountables_sellables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discountables_sellables` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discountable_id` int(11) DEFAULT NULL,
  `discountable_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `sellable_id` int(11) DEFAULT NULL,
  `sellable_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `apply_as` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discounts`
--

DROP TABLE IF EXISTS `discounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discountable_id` int(11) DEFAULT NULL,
  `discountable_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `apply_as` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `label` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `remaining` int(11) DEFAULT NULL,
  `benefactor_id` int(11) DEFAULT NULL,
  `benefactor_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discounts_certificates`
--

DROP TABLE IF EXISTS `discounts_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discounts_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discount_id` int(11) DEFAULT NULL,
  `certificate_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discounts_orders`
--

DROP TABLE IF EXISTS `discounts_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discounts_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `discount_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=266 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `domain_control_validations`
--

DROP TABLE IF EXISTS `domain_control_validations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `domain_control_validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `email_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `candidate_addresses` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `subject` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_to_find_identifier` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `identifier` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `identifier_found` tinyint(1) DEFAULT NULL,
  `responded_at` datetime DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `workflow_state` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `dcv_method` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `certificate_name_id` int(11) DEFAULT NULL,
  `failure_action` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `validation_compliance_id` int(11) DEFAULT NULL,
  `validation_compliance_date` datetime DEFAULT NULL,
  `csr_unique_value_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_domain_control_validations_on_id_csr_id` (`id`,`csr_id`),
  KEY `index_domain_control_validations_on_3_cols` (`certificate_name_id`,`email_address`,`dcv_method`),
  KEY `index_domain_control_validations_on_3_cols(2)` (`csr_id`,`email_address`,`dcv_method`),
  KEY `index_domain_control_validations_on_subject` (`subject`),
  KEY `index_domain_control_validations_on_workflow_state` (`workflow_state`)
) ENGINE=InnoDB AUTO_INCREMENT=240888 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `duo_accounts`
--

DROP TABLE IF EXISTS `duo_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `duo_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `duo_ikey` varchar(255) DEFAULT NULL,
  `duo_skey` varchar(255) DEFAULT NULL,
  `duo_akey` varchar(255) DEFAULT NULL,
  `duo_hostname` varchar(255) DEFAULT NULL,
  `encrypted_duo_ikey` varchar(255) DEFAULT NULL,
  `encrypted_duo_skey` varchar(255) DEFAULT NULL,
  `encrypted_duo_akey` varchar(255) DEFAULT NULL,
  `encrypted_duo_hostname` varchar(255) DEFAULT NULL,
  `encrypted_duo_ikey_salt` varchar(255) DEFAULT NULL,
  `encrypted_duo_ikey_iv` varchar(255) DEFAULT NULL,
  `encrypted_duo_skey_salt` varchar(255) DEFAULT NULL,
  `encrypted_duo_skey_iv` varchar(255) DEFAULT NULL,
  `encrypted_duo_akey_salt` varchar(255) DEFAULT NULL,
  `encrypted_duo_akey_iv` varchar(255) DEFAULT NULL,
  `encrypted_duo_hostname_salt` varchar(255) DEFAULT NULL,
  `encrypted_duo_hostname_iv` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `duplicate_v2_users`
--

DROP TABLE IF EXISTS `duplicate_v2_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `duplicate_v2_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=392 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `folders`
--

DROP TABLE IF EXISTS `folders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `folders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `default` tinyint(1) NOT NULL DEFAULT '0',
  `archived` tinyint(1) NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `ssl_account_id` int(11) NOT NULL,
  `items_count` int(11) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `expired` tinyint(1) DEFAULT '0',
  `active` tinyint(1) DEFAULT '0',
  `revoked` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_folders_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_folders_on_parent_id` (`parent_id`),
  KEY `index_folders_on_name` (`name`),
  KEY `index_folder_statuses` (`default`,`archived`,`name`,`ssl_account_id`,`expired`,`active`,`revoked`),
  KEY `index_folders_on_default_and_name_and_ssl_account_id` (`default`,`name`,`ssl_account_id`),
  KEY `index_folders_on_archived_and_name_and_ssl_account_id` (`archived`,`name`,`ssl_account_id`),
  KEY `index_folders_on_name_and_ssl_account_id_and_expired` (`name`,`ssl_account_id`,`expired`),
  KEY `index_folders_on_name_and_ssl_account_id_and_active_and_revoked` (`name`,`ssl_account_id`,`active`,`revoked`),
  KEY `index_folders_on_name_and_ssl_account_id_and_revoked` (`name`,`ssl_account_id`,`revoked`),
  KEY `index_folders_on_archived` (`archived`),
  KEY `index_folders_on_expired` (`expired`),
  KEY `index_folders_on_active` (`active`),
  KEY `index_folders_on_revoked` (`revoked`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `funded_accounts`
--

DROP TABLE IF EXISTS `funded_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `funded_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT '0',
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `currency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `card_declined` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_funded_accounts_on_ssl_account_id` (`ssl_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=474123 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gateways`
--

DROP TABLE IF EXISTS `gateways`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gateways` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `groupings`
--

DROP TABLE IF EXISTS `groupings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groupings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nav_tool` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=311 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `company` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_1` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_2` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fax` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vat` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tax` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `type` varchar(255) DEFAULT NULL,
  `billable_id` int(11) DEFAULT NULL,
  `billable_type` varchar(255) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `reference_number` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `default_payment` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=253 DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `legacy_v2_user_mappings`
--

DROP TABLE IF EXISTS `legacy_v2_user_mappings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `legacy_v2_user_mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `old_user_id` int(11) DEFAULT NULL,
  `user_mappable_id` int(11) DEFAULT NULL,
  `user_mappable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6181 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `line_items`
--

DROP TABLE IF EXISTS `line_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `line_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `affiliate_id` int(11) DEFAULT NULL,
  `sellable_id` int(11) DEFAULT NULL,
  `sellable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `affiliate_payout_rate` float DEFAULT NULL,
  `aff_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `qty` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_line_items_on_order_id` (`order_id`),
  KEY `index_line_items_on_sellable_id` (`sellable_id`),
  KEY `index_line_items_on_sellable_type` (`sellable_type`),
  KEY `index_line_items_on_sellable_id_and_sellable_type` (`sellable_id`,`sellable_type`),
  KEY `index_line_items_on_order_id_and_sellable_id_and_sellable_type` (`order_id`,`sellable_id`,`sellable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=70448 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mailboxer_conversation_opt_outs`
--

DROP TABLE IF EXISTS `mailboxer_conversation_opt_outs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mailboxer_conversation_opt_outs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unsubscriber_id` int(11) DEFAULT NULL,
  `unsubscriber_type` varchar(255) DEFAULT NULL,
  `conversation_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type` (`unsubscriber_id`,`unsubscriber_type`),
  KEY `index_mailboxer_conversation_opt_outs_on_conversation_id` (`conversation_id`),
  CONSTRAINT `mb_opt_outs_on_conversations_id` FOREIGN KEY (`conversation_id`) REFERENCES `mailboxer_conversations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mailboxer_conversations`
--

DROP TABLE IF EXISTS `mailboxer_conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mailboxer_conversations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject` varchar(255) DEFAULT '',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mailboxer_notifications`
--

DROP TABLE IF EXISTS `mailboxer_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mailboxer_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `body` text,
  `subject` varchar(255) DEFAULT '',
  `sender_id` int(11) DEFAULT NULL,
  `sender_type` varchar(255) DEFAULT NULL,
  `conversation_id` int(11) DEFAULT NULL,
  `draft` tinyint(1) DEFAULT '0',
  `notification_code` varchar(255) DEFAULT NULL,
  `notified_object_id` int(11) DEFAULT NULL,
  `notified_object_type` varchar(255) DEFAULT NULL,
  `attachment` varchar(255) DEFAULT NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `global` tinyint(1) DEFAULT '0',
  `expires` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_mailboxer_notifications_on_conversation_id` (`conversation_id`),
  KEY `index_mailboxer_notifications_on_type` (`type`),
  KEY `index_mailboxer_notifications_on_sender_id_and_sender_type` (`sender_id`,`sender_type`),
  KEY `index_mailboxer_notifications_on_notified_object_id_and_type` (`notified_object_id`,`notified_object_type`),
  CONSTRAINT `notifications_on_conversation_id` FOREIGN KEY (`conversation_id`) REFERENCES `mailboxer_conversations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mailboxer_receipts`
--

DROP TABLE IF EXISTS `mailboxer_receipts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mailboxer_receipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `receiver_id` int(11) DEFAULT NULL,
  `receiver_type` varchar(255) DEFAULT NULL,
  `notification_id` int(11) NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `trashed` tinyint(1) DEFAULT '0',
  `deleted` tinyint(1) DEFAULT '0',
  `mailbox_type` varchar(25) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `is_delivered` tinyint(1) DEFAULT '0',
  `delivery_method` varchar(255) DEFAULT NULL,
  `message_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_mailboxer_receipts_on_notification_id` (`notification_id`),
  KEY `index_mailboxer_receipts_on_receiver_id_and_receiver_type` (`receiver_id`,`receiver_type`),
  CONSTRAINT `receipts_on_notification_id` FOREIGN KEY (`notification_id`) REFERENCES `mailboxer_notifications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `malware_hashes`
--

DROP TABLE IF EXISTS `malware_hashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `malware_hashes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=726858 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `malwares`
--

DROP TABLE IF EXISTS `malwares`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `malwares` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `black_major` int(11) DEFAULT NULL,
  `black_minor` int(11) DEFAULT NULL,
  `malware_major` int(11) DEFAULT NULL,
  `malware_minor` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(50) COLLATE utf8_unicode_ci DEFAULT '',
  `note` text COLLATE utf8_unicode_ci,
  `notable_id` int(11) DEFAULT NULL,
  `notable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notes_on_notable_id` (`notable_id`),
  KEY `index_notes_on_notable_type` (`notable_type`),
  KEY `index_notes_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=146 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_groups`
--

DROP TABLE IF EXISTS `notification_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `ref` varchar(255) NOT NULL,
  `friendly_name` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `scan_port` varchar(255) DEFAULT '443',
  `notify_all` tinyint(1) DEFAULT '1',
  `status` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notification_groups_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_notification_groups_on_ssl_account_id_and_ref` (`ssl_account_id`,`ref`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_groups_contacts`
--

DROP TABLE IF EXISTS `notification_groups_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_groups_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email_address` varchar(255) DEFAULT NULL,
  `notification_group_id` int(11) DEFAULT NULL,
  `contactable_id` int(11) DEFAULT NULL,
  `contactable_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notification_groups_contacts_on_notification_group_id` (`notification_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_groups_subjects`
--

DROP TABLE IF EXISTS `notification_groups_subjects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_groups_subjects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_name` varchar(255) DEFAULT NULL,
  `notification_group_id` int(11) DEFAULT NULL,
  `subjectable_id` int(11) DEFAULT NULL,
  `subjectable_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_page` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notification_groups_subjects_on_notification_group_id` (`notification_group_id`),
  KEY `index_notification_groups_subjects_on_two_fields` (`subjectable_id`,`subjectable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oauth_nonces`
--

DROP TABLE IF EXISTS `oauth_nonces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_nonces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nonce` varchar(255) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_oauth_nonces_on_nonce_and_timestamp` (`nonce`,`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oauth_tokens`
--

DROP TABLE IF EXISTS `oauth_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `type` varchar(20) DEFAULT NULL,
  `client_application_id` int(11) DEFAULT NULL,
  `token` varchar(40) DEFAULT NULL,
  `secret` varchar(40) DEFAULT NULL,
  `callback_url` varchar(255) DEFAULT NULL,
  `verifier` varchar(20) DEFAULT NULL,
  `scope` varchar(255) DEFAULT NULL,
  `authorized_at` datetime DEFAULT NULL,
  `invalidated_at` datetime DEFAULT NULL,
  `valid_to` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_oauth_tokens_on_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_transactions`
--

DROP TABLE IF EXISTS `order_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `old_amount` int(11) DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `reference` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `action` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `params` text COLLATE utf8_unicode_ci,
  `avs` text COLLATE utf8_unicode_ci,
  `cvv` text COLLATE utf8_unicode_ci,
  `fraud_review` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `test` tinyint(1) DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=35131 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `billing_profile_id` int(11) DEFAULT NULL,
  `billable_id` int(11) DEFAULT NULL,
  `billable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `canceled_at` datetime DEFAULT NULL,
  `lock_version` int(11) DEFAULT '0',
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'pending',
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'active',
  `reference_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deducted_from_id` int(11) DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `po_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `quote_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `visitor_token_id` int(11) DEFAULT NULL,
  `ext_affiliate_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ext_affiliate_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ext_affiliate_credited` tinyint(1) DEFAULT NULL,
  `ext_customer_ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `approval` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `invoice_description` text COLLATE utf8_unicode_ci,
  `cur_wildcard` int(11) DEFAULT NULL,
  `cur_non_wildcard` int(11) DEFAULT NULL,
  `max_wildcard` int(11) DEFAULT NULL,
  `max_non_wildcard` int(11) DEFAULT NULL,
  `wildcard_cents` int(11) DEFAULT NULL,
  `non_wildcard_cents` int(11) DEFAULT NULL,
  `reseller_tier_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_orders_on_billable_id` (`billable_id`),
  KEY `index_orders_on_billable_type` (`billable_type`),
  KEY `index_orders_on_created_at` (`created_at`),
  KEY `index_orders_on_updated_at` (`updated_at`),
  KEY `index_orders_on_reference_number` (`reference_number`),
  KEY `index_orders_on_po_number` (`po_number`),
  KEY `index_orders_on_quote_number` (`quote_number`),
  KEY `index_orders_on_billable_id_and_billable_type` (`billable_id`,`billable_type`),
  KEY `index_orders_on_status` (`status`),
  KEY `index_orders_on_state_and_billable_id_and_billable_type` (`state`,`billable_id`,`billable_type`),
  KEY `index_orders_on_id_and_state` (`id`,`state`),
  KEY `index_orders_on_state_and_description_and_notes` (`state`,`description`,`notes`)
) ENGINE=InnoDB AUTO_INCREMENT=64006 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `other_party_requests`
--

DROP TABLE IF EXISTS `other_party_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `other_party_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `other_party_requestable_id` int(11) DEFAULT NULL,
  `other_party_requestable_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `email_addresses` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `identifier` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=448 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `address_id` int(11) DEFAULT NULL,
  `cents` int(11) DEFAULT NULL,
  `currency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `confirmation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cleared_at` datetime DEFAULT NULL,
  `voided_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `lock_version` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_payments_on_cleared_at` (`cleared_at`),
  KEY `index_payments_on_created_at` (`created_at`),
  KEY `index_payments_on_order_id` (`order_id`),
  KEY `index_payments_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `action` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject_class` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions_roles`
--

DROP TABLE IF EXISTS `permissions_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `permissions_roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `permission_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `physical_tokens`
--

DROP TABLE IF EXISTS `physical_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `physical_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `signed_certificate_id` int(11) DEFAULT NULL,
  `tracking_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `shipping_method` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `activation_pin` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `manufacturer` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `model_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `serial_number` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `workflow_state` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin_pin` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `management_key` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preferences`
--

DROP TABLE IF EXISTS `preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `owner_id` int(11) NOT NULL,
  `owner_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `group_id` int(11) DEFAULT NULL,
  `group_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_preferences_on_owner_id_and_owner_type` (`id`,`owner_id`,`owner_type`),
  UNIQUE KEY `index_preferences_on_id_and_owner_id_and_owner_type` (`id`,`owner_id`,`owner_type`),
  UNIQUE KEY `index_preferences_on_owner_and_name_and_preference` (`group_id`,`group_type`,`name`,`owner_id`,`owner_type`),
  KEY `index_preferences_on_owner_and_name_and_value` (`id`,`name`,`owner_id`,`owner_type`,`value`),
  KEY `index_preferences_on_name_and_value` (`id`,`name`,`value`),
  KEY `index_preferences_on_5_cols` (`group_id`,`group_type`,`owner_id`,`owner_type`,`value`),
  KEY `index_preferences_on_owner_type_and_owner_id` (`owner_type`,`owner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2572339 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_orders`
--

DROP TABLE IF EXISTS `product_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `workflow_state` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(191) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `auto_renew` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `auto_renew_status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_expired` tinyint(1) DEFAULT NULL,
  `value` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_product_orders_on_ref` (`ref`),
  KEY `index_product_orders_on_created_at` (`created_at`),
  KEY `index_product_orders_on_is_expired` (`is_expired`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_orders_sub_product_orders`
--

DROP TABLE IF EXISTS `product_orders_sub_product_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_orders_sub_product_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_order_id` int(11) DEFAULT NULL,
  `sub_product_order_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_variant_groups`
--

DROP TABLE IF EXISTS `product_variant_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_variant_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `variantable_id` int(11) DEFAULT NULL,
  `variantable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `text_only_description` text COLLATE utf8_unicode_ci,
  `display_order` int(11) DEFAULT NULL,
  `serial` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `published_as` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10190 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_variant_items`
--

DROP TABLE IF EXISTS `product_variant_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_variant_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_variant_group_id` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `text_only_description` text COLLATE utf8_unicode_ci,
  `amount` int(11) DEFAULT NULL,
  `display_order` int(11) DEFAULT NULL,
  `item_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `serial` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `published_as` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10963 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `value` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `summary` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `text_only_summary` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `text_only_description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `published_as` varchar(16) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT 'draft',
  `ref` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `serial` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `icons` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `auto_renew` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `display_order` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ext_customer_ref` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `products_sub_products`
--

DROP TABLE IF EXISTS `products_sub_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `products_sub_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) DEFAULT NULL,
  `sub_product_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `receipts`
--

DROP TABLE IF EXISTS `receipts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `receipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `confirmation_recipients` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `receipt_recipients` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processed_recipients` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deposit_reference_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deposit_created_at` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deposit_description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deposit_method` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `profile_full_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `profile_credit_card` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `profile_last_digits` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deposit_amount` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `available_funds` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_reference_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_created_at` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_descriptions` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `line_item_amounts` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_amount` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=980190963 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `refunds`
--

DROP TABLE IF EXISTS `refunds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `refunds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `merchant` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `reference` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `order_transaction_id` int(11) DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `partial_refund` tinyint(1) DEFAULT '0',
  `message` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `merchant_response` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `test` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_refunds_on_user_id` (`user_id`),
  KEY `index_refunds_on_order_id` (`order_id`),
  KEY `index_refunds_on_order_transaction_id` (`order_transaction_id`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `registered_agents`
--

DROP TABLE IF EXISTS `registered_agents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `registered_agents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ref` varchar(255) NOT NULL,
  `ssl_account_id` int(11) NOT NULL,
  `ip_address` varchar(255) NOT NULL,
  `mac_address` varchar(255) NOT NULL,
  `agent` varchar(255) NOT NULL,
  `friendly_name` varchar(255) DEFAULT NULL,
  `requester_id` int(11) DEFAULT NULL,
  `requested_at` datetime DEFAULT NULL,
  `approver_id` int(11) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `workflow_status` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reminder_triggers`
--

DROP TABLE IF EXISTS `reminder_triggers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reminder_triggers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `renewal_attempts`
--

DROP TABLE IF EXISTS `renewal_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `renewal_attempts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `order_transaction_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `renewal_notifications`
--

DROP TABLE IF EXISTS `renewal_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `renewal_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_order_id` int(11) DEFAULT NULL,
  `body` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `recipients` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reseller_tiers`
--

DROP TABLE IF EXISTS `reseller_tiers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reseller_tiers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `published_as` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resellers`
--

DROP TABLE IF EXISTS `resellers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resellers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `reseller_tier_id` int(11) DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address3` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `po_box` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ext` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fax` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tax_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type_organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=460 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `revocation_notifications`
--

DROP TABLE IF EXISTS `revocation_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `revocation_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) DEFAULT NULL,
  `fingerprints` text,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `revocations`
--

DROP TABLE IF EXISTS `revocations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `revocations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fingerprint` varchar(255) DEFAULT NULL,
  `replacement_fingerprint` varchar(255) DEFAULT NULL,
  `revoked_signed_certificate_id` int(11) DEFAULT NULL,
  `replacement_signed_certificate_id` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `message_before_revoked` text,
  `message_after_revoked` text,
  `revoked_on` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_revocations_on_fingerprint` (`fingerprint`),
  KEY `index_revocations_on_replacement_fingerprint` (`replacement_fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ssl_account_id` int(11) DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scan_logs`
--

DROP TABLE IF EXISTS `scan_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scan_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notification_group_id` int(11) DEFAULT NULL,
  `scanned_certificate_id` int(11) DEFAULT NULL,
  `domain_name` varchar(255) DEFAULT NULL,
  `scan_status` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `expiration_date` datetime DEFAULT NULL,
  `scan_group` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_scan_logs_on_notification_group_id` (`notification_group_id`),
  KEY `index_scan_logs_on_scanned_certificate_id` (`scanned_certificate_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scanned_certificates`
--

DROP TABLE IF EXISTS `scanned_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scanned_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `body` text,
  `decoded` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `serial` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schedules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notification_group_id` int(11) DEFAULT NULL,
  `schedule_type` varchar(255) NOT NULL,
  `schedule_value` varchar(255) NOT NULL DEFAULT '2',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_schedules_on_notification_group_id` (`notification_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sent_reminders`
--

DROP TABLE IF EXISTS `sent_reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sent_reminders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `signed_certificate_id` int(11) DEFAULT NULL,
  `body` text COLLATE utf8_unicode_ci,
  `recipients` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `trigger_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reminder_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contacts_on_recipients_subject_trigger_value_expires_at` (`recipients`,`subject`,`trigger_value`,`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `server_softwares`
--

DROP TABLE IF EXISTS `server_softwares`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_softwares` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `support_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(191) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `data` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shopping_carts`
--

DROP TABLE IF EXISTS `shopping_carts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shopping_carts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `guid` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `content` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `token` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `crypted_password` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_salt` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `access` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_shopping_carts_on_guid` (`guid`)
) ENGINE=InnoDB AUTO_INCREMENT=36122 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signed_certificates`
--

DROP TABLE IF EXISTS `signed_certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `signed_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `common_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization_unit` text COLLATE utf8_unicode_ci,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `effective_date` datetime DEFAULT NULL,
  `expiration_date` datetime DEFAULT NULL,
  `fingerprintSHA` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fingerprint` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `signature` text COLLATE utf8_unicode_ci,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `body` text COLLATE utf8_unicode_ci,
  `parent_cert` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `subject_alternative_names` text COLLATE utf8_unicode_ci,
  `strength` int(11) DEFAULT NULL,
  `certificate_lookup_id` int(11) DEFAULT NULL,
  `decoded` text COLLATE utf8_unicode_ci,
  `serial` text COLLATE utf8_unicode_ci NOT NULL,
  `ext_customer_ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` text COLLATE utf8_unicode_ci NOT NULL,
  `ca_id` int(11) DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `registered_agent_id` int(11) DEFAULT NULL,
  `ejbca_username` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_signed_certificates_on_csr_id` (`csr_id`),
  KEY `index_signed_certificates_on_common_name` (`common_name`),
  KEY `index_signed_certificates_on_ca_id` (`ca_id`),
  KEY `index_signed_certificates_on_strength` (`strength`),
  KEY `index_signed_certificates_on_3_cols` (`common_name`,`strength`),
  KEY `index_signed_certificates_on_fingerprint` (`fingerprint`),
  KEY `index_signed_certificates_on_ejbca_username` (`ejbca_username`),
  KEY `index_signed_certificates_on_csr_id_and_type` (`csr_id`,`type`),
  FULLTEXT KEY `index_signed_certificates_cn_u_b_d_ecf_eu` (`common_name`,`url`,`body`,`decoded`,`ext_customer_ref`,`ejbca_username`),
  CONSTRAINT `fk_rails_d21ca532b7` FOREIGN KEY (`ca_id`) REFERENCES `cas` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=55853 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `site_checks`
--

DROP TABLE IF EXISTS `site_checks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `site_checks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` text,
  `certificate_lookup_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `site_seals`
--

DROP TABLE IF EXISTS `site_seals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `site_seals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `seal_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_site_seals_ref` (`ref`),
  KEY `index_site_seals_workflow_state` (`workflow_state`)
) ENGINE=InnoDB AUTO_INCREMENT=62661 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ssl_account_users`
--

DROP TABLE IF EXISTS `ssl_account_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ssl_account_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `ssl_account_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `approved` tinyint(1) DEFAULT '0',
  `approval_token` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `token_expires` datetime DEFAULT NULL,
  `user_enabled` tinyint(1) DEFAULT '1',
  `invited_at` datetime DEFAULT NULL,
  `declined_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ssl_account_users_on_user_id` (`user_id`),
  KEY `index_ssl_account_users_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_ssl_account_users_on_ssl_account_id_and_user_id` (`ssl_account_id`,`user_id`),
  KEY `index_ssl_account_users_on_four_fields` (`user_id`,`ssl_account_id`,`approved`,`user_enabled`)
) ENGINE=InnoDB AUTO_INCREMENT=38396 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ssl_accounts`
--

DROP TABLE IF EXISTS `ssl_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ssl_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `acct_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT '--- []',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ssl_slug` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `company_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `issue_dv_no_validation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `billing_method` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'monthly',
  `duo_enabled` tinyint(1) DEFAULT NULL,
  `duo_own_used` tinyint(1) DEFAULT NULL,
  `sec_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `default_folder_id` int(11) DEFAULT NULL,
  `no_limit` tinyint(1) DEFAULT '0',
  `epki_agreement` datetime DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `index_ssl_account_on_acct_number` (`acct_number`),
  KEY `index_ssl_accounts_on_acct_number_and_company_name_and_ssl_slug` (`acct_number`,`company_name`,`ssl_slug`),
  KEY `index_ssl_accounts_on_id_and_created_at` (`id`,`created_at`),
  KEY `index_ssl_accounts_on_ssl_slug_and_acct_number` (`ssl_slug`,`acct_number`),
  FULLTEXT KEY `index_ssl_accounts_an_cn_ss` (`acct_number`,`company_name`,`ssl_slug`)
) ENGINE=InnoDB AUTO_INCREMENT=474118 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ssl_docs`
--

DROP TABLE IF EXISTS `ssl_docs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ssl_docs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `folder_id` int(11) DEFAULT NULL,
  `reviewer` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin_notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_file_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_file_size` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_updated_at` datetime DEFAULT NULL,
  `random_secret` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `processing` tinyint(1) DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `display_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=174 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sub_order_items`
--

DROP TABLE IF EXISTS `sub_order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sub_order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sub_itemable_id` int(11) DEFAULT NULL,
  `sub_itemable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `product_variant_item_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sub_order_items_on_sub_itemable` (`id`,`sub_itemable_id`,`sub_itemable_type`),
  KEY `index_sub_order_items_on_sub_itemable_id_and_sub_itemable_type` (`sub_itemable_id`,`sub_itemable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=72327 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `surl_blacklists`
--

DROP TABLE IF EXISTS `surl_blacklists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `surl_blacklists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fingerprint` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `surl_visits`
--

DROP TABLE IF EXISTS `surl_visits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `surl_visits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `surl_id` int(11) DEFAULT NULL,
  `visitor_token_id` int(11) DEFAULT NULL,
  `referer_host` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `referer_address` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `request_uri` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `http_user_agent` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `result` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_surl_visits_on_surl_id` (`surl_id`)
) ENGINE=InnoDB AUTO_INCREMENT=376776 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `surls`
--

DROP TABLE IF EXISTS `surls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `surls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `original` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `identifier` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `guid` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `username` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_salt` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `require_ssl` tinyint(1) DEFAULT NULL,
  `share` tinyint(1) DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8324 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_audits`
--

DROP TABLE IF EXISTS `system_audits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `system_audits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `owner_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `target_type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `action` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_system_audits_on_target_id_and_target_type` (`target_id`,`target_type`),
  KEY `index_system_audits_on_owner_id_and_owner_type` (`owner_id`,`owner_type`),
  KEY `index_system_audits_on_4_cols` (`target_id`,`target_type`,`owner_id`,`owner_type`)
) ENGINE=InnoDB AUTO_INCREMENT=19726 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taggings`
--

DROP TABLE IF EXISTS `taggings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `taggings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_id` int(11) NOT NULL,
  `taggable_id` int(11) NOT NULL,
  `taggable_type` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_taggings` (`taggable_type`,`taggable_id`,`tag_id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `index_taggings_on_taggable_type_and_taggable_id` (`taggable_type`,`taggable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `ssl_account_id` int(11) NOT NULL,
  `taggings_count` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tags_on_ssl_account_id` (`ssl_account_id`),
  KEY `index_tags_on_taggings_count` (`taggings_count`),
  KEY `index_tags_on_ssl_account_id_and_name` (`ssl_account_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tracked_urls`
--

DROP TABLE IF EXISTS `tracked_urls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tracked_urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` text COLLATE utf8_unicode_ci,
  `md5` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tracked_urls_on_md5_and_url` (`md5`(100),`url`(100)),
  KEY `index_tracked_urls_on_md5` (`md5`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trackings`
--

DROP TABLE IF EXISTS `trackings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `trackings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tracked_url_id` int(11) DEFAULT NULL,
  `visitor_token_id` int(11) DEFAULT NULL,
  `referer_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `remote_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `u2fs`
--

DROP TABLE IF EXISTS `u2fs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `u2fs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `certificate` text,
  `key_handle` varchar(255) DEFAULT NULL,
  `public_key` varchar(255) DEFAULT NULL,
  `counter` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `nick_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unsubscribes`
--

DROP TABLE IF EXISTS `unsubscribes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `unsubscribes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `specs` varchar(255) DEFAULT NULL,
  `domain` text,
  `email` text,
  `ref` text,
  `enforce` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `url_callbacks`
--

DROP TABLE IF EXISTS `url_callbacks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `url_callbacks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `callbackable_id` int(11) DEFAULT NULL,
  `callbackable_type` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `method` varchar(255) DEFAULT NULL,
  `auth` text,
  `headers` text,
  `parameters` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_groups`
--

DROP TABLE IF EXISTS `user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `roles` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT '--- []',
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `notes` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_groups_users`
--

DROP TABLE IF EXISTS `user_groups_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_groups_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `user_group_id` int(11) DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ssl_account_id` int(11) DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `crypted_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_salt` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `persistence_token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `single_access_token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `perishable_token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT '0',
  `failed_login_count` int(11) NOT NULL DEFAULT '0',
  `last_request_at` datetime DEFAULT NULL,
  `current_login_at` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `current_login_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_login_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `openid_identifier` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address3` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `po_box` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `is_auth_token` tinyint(1) DEFAULT NULL,
  `default_ssl_account` int(11) DEFAULT NULL,
  `max_teams` int(11) DEFAULT NULL,
  `main_ssl_account` int(11) DEFAULT NULL,
  `persist_notice` tinyint(1) DEFAULT '0',
  `duo_enabled` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'enabled',
  PRIMARY KEY (`id`),
  KEY `index_users_on_email` (`email`),
  KEY `index_users_on_perishable_token` (`perishable_token`),
  KEY `index_users_on_login` (`login`),
  KEY `index_users_on_status` (`id`,`status`),
  KEY `index_users_on_status_and_ssl_account_id` (`id`,`ssl_account_id`,`status`),
  KEY `index_users_on_login_and_email` (`login`,`email`),
  KEY `index_users_on_ssl_acount_id` (`ssl_account_id`),
  KEY `index_users_on_ssl_account_id_and_login_and_email` (`ssl_account_id`,`login`,`email`),
  KEY `index_users_on_default_ssl_account` (`default_ssl_account`),
  KEY `index_users_on_status_and_login_and_email` (`status`,`login`,`email`),
  FULLTEXT KEY `index_users_l_e` (`login`,`email`)
) ENGINE=InnoDB AUTO_INCREMENT=1322687 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `v2_migration_progresses`
--

DROP TABLE IF EXISTS `v2_migration_progresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `v2_migration_progresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_table_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `migratable_id` int(11) DEFAULT NULL,
  `migratable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `migrated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=124152 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_compliances`
--

DROP TABLE IF EXISTS `validation_compliances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_compliances` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document` varchar(255) DEFAULT NULL,
  `version` varchar(255) DEFAULT NULL,
  `section` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_histories`
--

DROP TABLE IF EXISTS `validation_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_id` int(11) DEFAULT NULL,
  `reviewer` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin_notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_file_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_file_size` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `document_updated_at` datetime DEFAULT NULL,
  `random_secret` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `publish_to_site_seal` tinyint(1) DEFAULT NULL,
  `publish_to_site_seal_approval` tinyint(1) DEFAULT '0',
  `satisfies_validation_methods` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_validation_histories_validation_id` (`validation_id`),
  KEY `index_validation_histories_on_validation_id` (`validation_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2295 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_history_validations`
--

DROP TABLE IF EXISTS `validation_history_validations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_history_validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_history_id` int(11) DEFAULT NULL,
  `validation_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2236 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_rules`
--

DROP TABLE IF EXISTS `validation_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `operator` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `applicable_validation_methods` text COLLATE utf8_unicode_ci,
  `required_validation_methods` text COLLATE utf8_unicode_ci,
  `required_validation_methods_operator` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'AND',
  `notes` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_rulings`
--

DROP TABLE IF EXISTS `validation_rulings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_rulings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_rule_id` int(11) DEFAULT NULL,
  `validation_rulable_id` int(11) DEFAULT NULL,
  `validation_rulable_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_validation_rulings_on_validation_rule_id` (`validation_rule_id`),
  KEY `index_validation_rulings_on_rulable_id_and_rulable_type` (`validation_rulable_id`,`validation_rulable_type`)
) ENGINE=InnoDB AUTO_INCREMENT=1060748454 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validation_rulings_validation_histories`
--

DROP TABLE IF EXISTS `validation_rulings_validation_histories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validation_rulings_validation_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `validation_history_id` int(11) DEFAULT NULL,
  `validation_ruling_id` int(11) DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `validations`
--

DROP TABLE IF EXISTS `validations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `validations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `organization` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contact_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tax_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `workflow_state` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `domain` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=62688 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visitor_tokens`
--

DROP TABLE IF EXISTS `visitor_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `visitor_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `affiliate_id` int(11) DEFAULT NULL,
  `guid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_visitor_tokens_on_guid_and_affiliate_id` (`guid`,`affiliate_id`),
  KEY `index_visitor_tokens_on_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `websites`
--

DROP TABLE IF EXISTS `websites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `websites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `api_host` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `type` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `db_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `whois_lookups`
--

DROP TABLE IF EXISTS `whois_lookups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `whois_lookups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `csr_id` int(11) DEFAULT NULL,
  `raw` text COLLATE utf8_unicode_ci,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `record_created_on` datetime DEFAULT NULL,
  `expiration` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-10-31 14:58:42
INSERT INTO schema_migrations (version) VALUES ('20100121221021');

INSERT INTO schema_migrations (version) VALUES ('20100122044255');

INSERT INTO schema_migrations (version) VALUES ('20100124195538');

INSERT INTO schema_migrations (version) VALUES ('20100124195613');

INSERT INTO schema_migrations (version) VALUES ('20100125211522');

INSERT INTO schema_migrations (version) VALUES ('20100126175403');

INSERT INTO schema_migrations (version) VALUES ('20100126183131');

INSERT INTO schema_migrations (version) VALUES ('20100126191936');

INSERT INTO schema_migrations (version) VALUES ('20100126192548');

INSERT INTO schema_migrations (version) VALUES ('20100126192837');

INSERT INTO schema_migrations (version) VALUES ('20100126194023');

INSERT INTO schema_migrations (version) VALUES ('20100126194244');

INSERT INTO schema_migrations (version) VALUES ('20100126195542');

INSERT INTO schema_migrations (version) VALUES ('20100126200609');

INSERT INTO schema_migrations (version) VALUES ('20100126200704');

INSERT INTO schema_migrations (version) VALUES ('20100126200716');

INSERT INTO schema_migrations (version) VALUES ('20100201220711');

INSERT INTO schema_migrations (version) VALUES ('20100201235957');

INSERT INTO schema_migrations (version) VALUES ('20100213190715');

INSERT INTO schema_migrations (version) VALUES ('20100213191000');

INSERT INTO schema_migrations (version) VALUES ('20100217042956');

INSERT INTO schema_migrations (version) VALUES ('20100218203748');

INSERT INTO schema_migrations (version) VALUES ('20100303002756');

INSERT INTO schema_migrations (version) VALUES ('20100309223207');

INSERT INTO schema_migrations (version) VALUES ('20100315152101');

INSERT INTO schema_migrations (version) VALUES ('20100318032118');

INSERT INTO schema_migrations (version) VALUES ('20100319100957');

INSERT INTO schema_migrations (version) VALUES ('20100323022436');

INSERT INTO schema_migrations (version) VALUES ('20100420222202');

INSERT INTO schema_migrations (version) VALUES ('20100420222227');

INSERT INTO schema_migrations (version) VALUES ('20100528061603');

INSERT INTO schema_migrations (version) VALUES ('20100528062845');

INSERT INTO schema_migrations (version) VALUES ('20100529211634');

INSERT INTO schema_migrations (version) VALUES ('20100530202931');

INSERT INTO schema_migrations (version) VALUES ('20100604202312');

INSERT INTO schema_migrations (version) VALUES ('20100616170837');

INSERT INTO schema_migrations (version) VALUES ('20100622214848');

INSERT INTO schema_migrations (version) VALUES ('20100719190953');

INSERT INTO schema_migrations (version) VALUES ('20100809215106');

INSERT INTO schema_migrations (version) VALUES ('20100921154727');

INSERT INTO schema_migrations (version) VALUES ('20100921155158');

INSERT INTO schema_migrations (version) VALUES ('20100923222042');

INSERT INTO schema_migrations (version) VALUES ('20101018220842');

INSERT INTO schema_migrations (version) VALUES ('20101019040011');

INSERT INTO schema_migrations (version) VALUES ('20101019135512');

INSERT INTO schema_migrations (version) VALUES ('20101031183441');

INSERT INTO schema_migrations (version) VALUES ('20101210164349');

INSERT INTO schema_migrations (version) VALUES ('20101213233052');

INSERT INTO schema_migrations (version) VALUES ('20101218195702');

INSERT INTO schema_migrations (version) VALUES ('20101231223811');

INSERT INTO schema_migrations (version) VALUES ('20110127235349');

INSERT INTO schema_migrations (version) VALUES ('20110204103124');

INSERT INTO schema_migrations (version) VALUES ('20110404202432');

INSERT INTO schema_migrations (version) VALUES ('20110427215546');

INSERT INTO schema_migrations (version) VALUES ('20110428222053');

INSERT INTO schema_migrations (version) VALUES ('20110502181625');

INSERT INTO schema_migrations (version) VALUES ('20110622154343');

INSERT INTO schema_migrations (version) VALUES ('20110623211829');

INSERT INTO schema_migrations (version) VALUES ('20110625192901');

INSERT INTO schema_migrations (version) VALUES ('20110701233837');

INSERT INTO schema_migrations (version) VALUES ('20110705161309');

INSERT INTO schema_migrations (version) VALUES ('20110721204705');

INSERT INTO schema_migrations (version) VALUES ('20110907164002');

INSERT INTO schema_migrations (version) VALUES ('20111006185028');

INSERT INTO schema_migrations (version) VALUES ('20111022194008');

INSERT INTO schema_migrations (version) VALUES ('20111024004450');

INSERT INTO schema_migrations (version) VALUES ('20111114194244');

INSERT INTO schema_migrations (version) VALUES ('20111202162405');

INSERT INTO schema_migrations (version) VALUES ('20120124224059');

INSERT INTO schema_migrations (version) VALUES ('20120127025217');

INSERT INTO schema_migrations (version) VALUES ('20120321191020');

INSERT INTO schema_migrations (version) VALUES ('20120612134625');

INSERT INTO schema_migrations (version) VALUES ('20120612195043');

INSERT INTO schema_migrations (version) VALUES ('20120621213833');

INSERT INTO schema_migrations (version) VALUES ('20120709162131');

INSERT INTO schema_migrations (version) VALUES ('20120709162402');

INSERT INTO schema_migrations (version) VALUES ('20120711163116');

INSERT INTO schema_migrations (version) VALUES ('20120718172856');

INSERT INTO schema_migrations (version) VALUES ('20120718185153');

INSERT INTO schema_migrations (version) VALUES ('20120906161230');

INSERT INTO schema_migrations (version) VALUES ('20120907225728');

INSERT INTO schema_migrations (version) VALUES ('20120912181108');

INSERT INTO schema_migrations (version) VALUES ('20120913155722');

INSERT INTO schema_migrations (version) VALUES ('20120914215852');

INSERT INTO schema_migrations (version) VALUES ('20130211054329');

INSERT INTO schema_migrations (version) VALUES ('20131206151716');

INSERT INTO schema_migrations (version) VALUES ('20140706202544');

INSERT INTO schema_migrations (version) VALUES ('20140706202850');

INSERT INTO schema_migrations (version) VALUES ('20140716180357');

INSERT INTO schema_migrations (version) VALUES ('20140916204604');

INSERT INTO schema_migrations (version) VALUES ('20141010141810');

INSERT INTO schema_migrations (version) VALUES ('20141015203833');

INSERT INTO schema_migrations (version) VALUES ('20141018184115');

INSERT INTO schema_migrations (version) VALUES ('20141028161640');

INSERT INTO schema_migrations (version) VALUES ('20141103202452');

INSERT INTO schema_migrations (version) VALUES ('20141110172807');

INSERT INTO schema_migrations (version) VALUES ('20141113233608');

INSERT INTO schema_migrations (version) VALUES ('20141114192523');

INSERT INTO schema_migrations (version) VALUES ('20141130203217');

INSERT INTO schema_migrations (version) VALUES ('20141208183048');

INSERT INTO schema_migrations (version) VALUES ('20141209154127');

INSERT INTO schema_migrations (version) VALUES ('20150120172229');

INSERT INTO schema_migrations (version) VALUES ('20150213192921');

INSERT INTO schema_migrations (version) VALUES ('20150213193440');

INSERT INTO schema_migrations (version) VALUES ('20150313191541');

INSERT INTO schema_migrations (version) VALUES ('20150505183402');

INSERT INTO schema_migrations (version) VALUES ('20150629224035');

INSERT INTO schema_migrations (version) VALUES ('20150803202258');

INSERT INTO schema_migrations (version) VALUES ('20160311190854');

INSERT INTO schema_migrations (version) VALUES ('20160316225623');

INSERT INTO schema_migrations (version) VALUES ('20160317042437');

INSERT INTO schema_migrations (version) VALUES ('20160318165011');

INSERT INTO schema_migrations (version) VALUES ('20160707163529');

INSERT INTO schema_migrations (version) VALUES ('20161007224523');

INSERT INTO schema_migrations (version) VALUES ('20161007234903');

INSERT INTO schema_migrations (version) VALUES ('20161010202422');

INSERT INTO schema_migrations (version) VALUES ('20161018191559');

INSERT INTO schema_migrations (version) VALUES ('20161111214702');

INSERT INTO schema_migrations (version) VALUES ('20161122002959');

INSERT INTO schema_migrations (version) VALUES ('20161205210348');

INSERT INTO schema_migrations (version) VALUES ('20170109193640');

INSERT INTO schema_migrations (version) VALUES ('20170223224741');

INSERT INTO schema_migrations (version) VALUES ('20170417221448');

INSERT INTO schema_migrations (version) VALUES ('20170425030847');

INSERT INTO schema_migrations (version) VALUES ('20170515211433');

INSERT INTO schema_migrations (version) VALUES ('20170530231345');

INSERT INTO schema_migrations (version) VALUES ('20170703231345');

INSERT INTO schema_migrations (version) VALUES ('20170714231345');

INSERT INTO schema_migrations (version) VALUES ('20170724150634');

INSERT INTO schema_migrations (version) VALUES ('20170824154146');

INSERT INTO schema_migrations (version) VALUES ('20171029160707');

INSERT INTO schema_migrations (version) VALUES ('20171101154146');

INSERT INTO schema_migrations (version) VALUES ('20171107214114');

INSERT INTO schema_migrations (version) VALUES ('20171110052747');

INSERT INTO schema_migrations (version) VALUES ('20171110052748');

INSERT INTO schema_migrations (version) VALUES ('20171126210209');

INSERT INTO schema_migrations (version) VALUES ('20171128065202');

INSERT INTO schema_migrations (version) VALUES ('20171201154843');

INSERT INTO schema_migrations (version) VALUES ('20171206142451');

INSERT INTO schema_migrations (version) VALUES ('20171207223422');

INSERT INTO schema_migrations (version) VALUES ('20171227203946');

INSERT INTO schema_migrations (version) VALUES ('20180105231017');

INSERT INTO schema_migrations (version) VALUES ('20180113195551');

INSERT INTO schema_migrations (version) VALUES ('20180120220610');

INSERT INTO schema_migrations (version) VALUES ('20180127195410');

INSERT INTO schema_migrations (version) VALUES ('20180131221604');

INSERT INTO schema_migrations (version) VALUES ('20180202231505');

INSERT INTO schema_migrations (version) VALUES ('20180204155912');

INSERT INTO schema_migrations (version) VALUES ('20180208165438');

INSERT INTO schema_migrations (version) VALUES ('20180216083313');

INSERT INTO schema_migrations (version) VALUES ('20180222185458');

INSERT INTO schema_migrations (version) VALUES ('20180227180106');

INSERT INTO schema_migrations (version) VALUES ('20180301161917');

INSERT INTO schema_migrations (version) VALUES ('20180316010525');

INSERT INTO schema_migrations (version) VALUES ('20180321222639');

INSERT INTO schema_migrations (version) VALUES ('20180322223005');

INSERT INTO schema_migrations (version) VALUES ('20180324222045');

INSERT INTO schema_migrations (version) VALUES ('20180327193455');

INSERT INTO schema_migrations (version) VALUES ('20180404162536');

INSERT INTO schema_migrations (version) VALUES ('20180417143053');

INSERT INTO schema_migrations (version) VALUES ('20180425221036');

INSERT INTO schema_migrations (version) VALUES ('20180503174425');

INSERT INTO schema_migrations (version) VALUES ('20180511155358');

INSERT INTO schema_migrations (version) VALUES ('20180511164521');

INSERT INTO schema_migrations (version) VALUES ('20180511172930');

INSERT INTO schema_migrations (version) VALUES ('20180511172931');

INSERT INTO schema_migrations (version) VALUES ('20180515215437');

INSERT INTO schema_migrations (version) VALUES ('20180522042523');

INSERT INTO schema_migrations (version) VALUES ('20180522043630');

INSERT INTO schema_migrations (version) VALUES ('20180523163100');

INSERT INTO schema_migrations (version) VALUES ('20180523223416');

INSERT INTO schema_migrations (version) VALUES ('20180531230134');

INSERT INTO schema_migrations (version) VALUES ('20180605174118');

INSERT INTO schema_migrations (version) VALUES ('20180605181336');

INSERT INTO schema_migrations (version) VALUES ('20180608202612');

INSERT INTO schema_migrations (version) VALUES ('20180625174208');

INSERT INTO schema_migrations (version) VALUES ('20180629182134');

INSERT INTO schema_migrations (version) VALUES ('20180707153949');

INSERT INTO schema_migrations (version) VALUES ('20180707154006');

INSERT INTO schema_migrations (version) VALUES ('20180707154020');

INSERT INTO schema_migrations (version) VALUES ('20180716144434');

INSERT INTO schema_migrations (version) VALUES ('20180729001349');

INSERT INTO schema_migrations (version) VALUES ('20180730032858');

INSERT INTO schema_migrations (version) VALUES ('20180801163609');

INSERT INTO schema_migrations (version) VALUES ('20180802002757');

INSERT INTO schema_migrations (version) VALUES ('20180802185351');

INSERT INTO schema_migrations (version) VALUES ('20180803200958');

INSERT INTO schema_migrations (version) VALUES ('20180807080855');

INSERT INTO schema_migrations (version) VALUES ('20180808233242');

INSERT INTO schema_migrations (version) VALUES ('20180809085943');

INSERT INTO schema_migrations (version) VALUES ('20180810145959');

INSERT INTO schema_migrations (version) VALUES ('20180811165627');

INSERT INTO schema_migrations (version) VALUES ('20180814074956');

INSERT INTO schema_migrations (version) VALUES ('20180816101419');

INSERT INTO schema_migrations (version) VALUES ('20180816141802');

INSERT INTO schema_migrations (version) VALUES ('20180820025703');

INSERT INTO schema_migrations (version) VALUES ('20180820155859');

INSERT INTO schema_migrations (version) VALUES ('20180822094222');

INSERT INTO schema_migrations (version) VALUES ('20180822160626');

INSERT INTO schema_migrations (version) VALUES ('20180823073440');

INSERT INTO schema_migrations (version) VALUES ('20180823174238');

INSERT INTO schema_migrations (version) VALUES ('20180826221903');

INSERT INTO schema_migrations (version) VALUES ('20180831035328');

INSERT INTO schema_migrations (version) VALUES ('20180831190516');

INSERT INTO schema_migrations (version) VALUES ('20180904143640');

INSERT INTO schema_migrations (version) VALUES ('20180904162054');

INSERT INTO schema_migrations (version) VALUES ('20180905135124');

INSERT INTO schema_migrations (version) VALUES ('20180910095626');

INSERT INTO schema_migrations (version) VALUES ('20180912022511');

INSERT INTO schema_migrations (version) VALUES ('20180913183330');

INSERT INTO schema_migrations (version) VALUES ('20180914183330');

INSERT INTO schema_migrations (version) VALUES ('20180919181014');

INSERT INTO schema_migrations (version) VALUES ('20180920032908');

INSERT INTO schema_migrations (version) VALUES ('20180921225848');

INSERT INTO schema_migrations (version) VALUES ('20180926193514');

INSERT INTO schema_migrations (version) VALUES ('20180928164527');

INSERT INTO schema_migrations (version) VALUES ('20180928164528');

INSERT INTO schema_migrations (version) VALUES ('20180928164544');

INSERT INTO schema_migrations (version) VALUES ('20180928185802');

INSERT INTO schema_migrations (version) VALUES ('20180928200828');

INSERT INTO schema_migrations (version) VALUES ('20181009161215');

INSERT INTO schema_migrations (version) VALUES ('20181010164417');

INSERT INTO schema_migrations (version) VALUES ('20181013194238');

INSERT INTO schema_migrations (version) VALUES ('20181119181801');

INSERT INTO schema_migrations (version) VALUES ('20181119181802');

INSERT INTO schema_migrations (version) VALUES ('20181119181803');

INSERT INTO schema_migrations (version) VALUES ('20181119181804');

INSERT INTO schema_migrations (version) VALUES ('20181230194446');

INSERT INTO schema_migrations (version) VALUES ('20190103163143');

INSERT INTO schema_migrations (version) VALUES ('20190112045816');

INSERT INTO schema_migrations (version) VALUES ('20190115132031');

INSERT INTO schema_migrations (version) VALUES ('20190123152553');

INSERT INTO schema_migrations (version) VALUES ('20190125154611');

INSERT INTO schema_migrations (version) VALUES ('20190130091703');

INSERT INTO schema_migrations (version) VALUES ('20190130212834');

INSERT INTO schema_migrations (version) VALUES ('20190207225048');

INSERT INTO schema_migrations (version) VALUES ('20190218163457');

INSERT INTO schema_migrations (version) VALUES ('20190218225636');

INSERT INTO schema_migrations (version) VALUES ('20190314173012');

INSERT INTO schema_migrations (version) VALUES ('20190317135455');

INSERT INTO schema_migrations (version) VALUES ('20190328144703');

INSERT INTO schema_migrations (version) VALUES ('20190401203404');

INSERT INTO schema_migrations (version) VALUES ('20190401205730');

INSERT INTO schema_migrations (version) VALUES ('20190415204615');

INSERT INTO schema_migrations (version) VALUES ('20190423103116');

INSERT INTO schema_migrations (version) VALUES ('20190510072618');

INSERT INTO schema_migrations (version) VALUES ('20190510161052');

INSERT INTO schema_migrations (version) VALUES ('20190511133942');

INSERT INTO schema_migrations (version) VALUES ('20190523204615');

INSERT INTO schema_migrations (version) VALUES ('20190605164300');

INSERT INTO schema_migrations (version) VALUES ('20190613165106');

INSERT INTO schema_migrations (version) VALUES ('20190628184907');

INSERT INTO schema_migrations (version) VALUES ('20190707004026');

INSERT INTO schema_migrations (version) VALUES ('20190708164334');

INSERT INTO schema_migrations (version) VALUES ('20190813161628');

INSERT INTO schema_migrations (version) VALUES ('20191010161628');

INSERT INTO schema_migrations (version) VALUES ('20191010161629');

INSERT INTO schema_migrations (version) VALUES ('20191010161630');

INSERT INTO schema_migrations (version) VALUES ('20191017161630');

INSERT INTO schema_migrations (version) VALUES ('20191022191034');

INSERT INTO schema_migrations (version) VALUES ('20191022230612');

