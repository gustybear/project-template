###### Set the remote git repo and branch. ############
GITHUB_REPO                   :=

###### Set the remote aws s3 bucket for data. #########
S3_BUCKET                     :=

###### Set the exclude folders for data sync ##########
###### NOTE: use '=' instead of ':=' so the ###########
######       variables are expanded when use ##########
RSYNC_DATA_EXCLUDE            =

###### Add the folders ready to be published to #######
###### the list. The default folders in the ###########
###### template are: "report conf jnl slides." ########
PROJECT_DOCS_READY            :=

###### The parameters passed via the make command #####
###### specifying the folders to publish ##############
###### the webpages and materials. ####################
PUBLISH_WEBPAGES_DIR          :=
PUBLISH_MATERIALS_DIR         :=
###### Set this flag when the webpage is ready. #######
PROJECT_WEBPAGES_READY        :=
