CREATE TABLE IF NOT EXISTS `construcciones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(64) NOT NULL,
  `x` varchar(50) NOT NULL DEFAULT '0.00',
  `y` char(50) NOT NULL DEFAULT '0.00',
  `z` varchar(50) NOT NULL DEFAULT '0.00',
  `rot_x` varchar(50) NOT NULL DEFAULT '0.00',
  `rot_y` varchar(50) NOT NULL DEFAULT '0.00',
  `rot_z` varchar(50) NOT NULL DEFAULT '0.00',
  `owner` varchar(50) NOT NULL,
  `state` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2145 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;