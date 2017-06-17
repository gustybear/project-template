###### Set the remote git repo and branch. ############
GIT_REPO                      :=

###### Set the remote aws s3 bucket for data. #########
S3_BUCKET                     :=
DATA_RSYNC_EXCLUDE            := --exclude "$(S3_SUBDIR)/" --exclude "$(ARCHIVE_SUBDIR)/"
DATA_SSYNC_EXCLUDE            := --exclude "$(ARCHIVE_SUBDIR)/*"

###### The parameters passed via the make command #####
###### specifying the folders to publish ##############
###### the webpages and materials. ####################
PUBLISH_WEBPAGES_DIR          :=
PUBLISH_MATERIALS_DIR         :=

###### Add the folders ready to be published to #######
###### the list. The default folders in the ###########
###### template are: "report conf jnl slides." ########
PROJECT_DOCS_READY            :=

###### Add the folders ready to be packed to ##########
###### the list. The default folders in the ###########
###### template are: "report conf jnl slides." ########
PROJECT_DOCPACS_READY         :=

###### Set this flag when the webpage is ready. #######
PROJECT_WEBPAGES_READY        :=
