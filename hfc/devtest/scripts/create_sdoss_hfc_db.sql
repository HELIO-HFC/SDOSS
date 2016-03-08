--
-- Table structure for table `HISTORY`
--

DROP TABLE IF EXISTS `HISTORY`;
CREATE TABLE `HISTORY`(
  `ID` integer primary key, -- Primary id
  `FILEID` text, -- file id --
  `IC_FILE` text, -- Name of the HMI Ic data file
  `M_FILE` text, -- Name of the HMI M data file 
  `IC_URL` text, -- Ic Data file URL
  `M_URL` text, -- M Data file URL
  `INIT_FILE` text, -- Name of the int. output file
  `FEAT_FILE` text, -- Name of the feat. output file
  `TRACK_FILE` text, -- Name of the track. output file
  `STATUS`  text, -- Processing status
  `COMMENT` text -- Any useful comment
);
