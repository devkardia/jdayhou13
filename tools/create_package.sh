#!/bin/bash

#extension name mainly for extension's xml file
APP="mod_articlesplacedanywhere"

#the name of the extensions' zip file without .zip
ZIP_NAME="mod_articlesplacedanywhere"

#name of the folder in which the extension is located
APP_PATH="apa"

#full path to the extension folder
FULLPATH="/Users/alan/jdayhou13/$APP_PATH"

#location of Akeeba Release Maker
RMSCRIPT="/Users/alan/jdayhou13/rm/index.php"

echo $FULLPATH

#cd into extension's folder
cd $FULLPATH

case $1 in
	packit)
        #make a temporary path for packaging
        TMPPATH="/tmp/$APP"
        mkdir $TMPPATH

        #copy all applicable files/folders to the temp folder for packaging
        rsync -rv --exclude=".*/" --exclude=".DS_Store" --exclude="*.zip" --exclude="docs" --exclude="package" --exclude="tools" --exclude="*.md" $FULLPATH/* $TMPPATH/

        #take note of the current git revision
        VERSION=`git rev-list --all | wc -l | tr -d ' '`

		case $2 in
			#creates a new package of current git revision; does not get uploaded to site
			developer)
				#update the extensions version number to the current revision
				mv $TMPPATH/$APP.xml $TMPPATH/$APP.tmp
				sed "s/<version>.*<\/version>/<version>r$VERSION<\/version>/g" $TMPPATH/$APP.tmp > $TMPPATH/$APP.xml
				rm $TMPPATH/$APP.tmp

				echo ""
				echo "Set to revision $VERSION."

				#don't allow overwriting of existing revisions just in case you are packaging something you've not committed yet
				if [ -f "$FULLPATH/tools/${ZIP_NAME}_r${VERSION}.zip" ]
				then
					VERSION="WORKING"
				fi

				VERSIONPATH="packages/developer"
				VERSIONNAME="${ZIP_NAME}_r$VERSION"

				;;
			#prepares and creates a release
			release)
				if [ -z "$3" ]
				then
					echo "A release number is required."
					rm -r $TMPPATH
					exit;
				fi

				#update the extensions version number
				mv $TMPPATH/$APP.xml $TMPPATH/$APP.tmp
				sed "s/<version>.*<\/version>/<version>$3<\/version>/g" $TMPPATH/$APP.tmp > $TMPPATH/$APP.xml
				rm $TMPPATH/$APP.tmp

				#update the version number Akeeba Release Maker will use
				mv $FULLPATH/tools/config.json $FULLPATH/tools/config.tmp
				sed "s/\"common\.version\": \".*\",/\"common\.version\": \"$3\",/g" $FULLPATH/tools/config.tmp > $FULLPATH/tools/config.json
				rm $FULLPATH/tools/config.tmp

				VERSIONPATH="packages/release"
				VERSIONNAME="${ZIP_NAME}_v$3"

				#delete any current release zips so that Akeeba Release Maker doesn't reprocess them
				rm $FULLPATH/tools/packages/release/*.zip

				#create changelog based on git revisions

				#only pull revisions from the last time a release was made
				RELEASEDATEFILE="$FULLPATH/tools/LASTRELEASE"
				LASTRELEASE=$(head -n 1 $RELEASEDATEFILE)
				mv $RELEASEDATEFILE $RELEASEDATEFILE.previous
				wait

				#pull those commits and put them into the log
				mv $FULLPATH/CHANGELOG $FULLPATH/tools/CHANGELOG.previous
cat > $FULLPATH/CHANGELOG.tmp <<EOF



`git log --pretty=format:"%s" --since="$LASTRELEASE"`
EOF
				#clean up the log a bit
				grep -ve "^\\$" $FULLPATH/CHANGELOG.tmp > CHANGELOG
				wait

				rm $FULLPATH/CHANGELOG.tmp

				#update the release date to now
				RELEASEDATE=`date +"%Y-%m-%d %T %z"`
				printf "%s" "$RELEASEDATE" > $RELEASEDATEFILE
				wait
				;;

				*)
					echo "Should this be packaged for developer or release?"
					rm -r $TMPPATH
					exit
					;;
		esac

		#package it up; using 7z here but you could use another archival option
		/usr/bin/7z a "$FULLPATH/tools/$VERSIONPATH/$VERSIONNAME.zip" $TMPPATH/* '-xr!.*' '-x!*.zip' '-xr!nbproject' > /dev/null 2>&1
		rm -r $TMPPATH
	;;
	releaseit)
		#create the new release
		php $RMSCRIPT $FULLPATH/tools/config.json
		wait
		;;
    *)
        echo "packit or releaseit?"
        ;;
esac
exit 0