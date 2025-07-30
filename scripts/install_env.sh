# !/bin/bash

INSTALL_DIR="$HOME/.local"
CLONE_DIR="$INSTALL_DIR/misc_files"
ENV_FILE="$INSTALL_DIR/env.sh"

if [ "$1" == "remove" ]; then
	if [ -d "$CLONE_DIR" ]; then
		rm -rf "$CLONE_DIR"
		echo "Removed directory $CLONE_DIR."
	else
		echo "Directory $CLONE_DIR does not exist."
	fi

	if [ -f "$ENV_FILE" ]; then
		# del line of about $CLONE_DIR
		sed -i "/misc_files\/scripts/d" "$ENV_FILE"
		echo "Removed line containing $CLONE_DIR from $ENV_FILE."
	else
		echo "Environment file $ENV_FILE does not exist."
	fi

	exit 0
fi

mkdir -p "$INSTALL_DIR"

if [ -d "$CLONE_DIR" ]; then
	echo "Directory $CLONE_DIR already exists."
else
	git clone https://github.com/Licay/misc_files.git "$CLONE_DIR" --depth=1 --branch script_only
	if [ $? -eq 0 ]; then
		echo "Successfully cloned misc_files to $CLONE_DIR."
	else
		echo "Failed to clone misc_files."
		exit 1
	fi
fi

if [ ! -f "$ENV_FILE" ]; then
	touch "$ENV_FILE"
	chmod +x "$ENV_FILE"
	echo "Created environment file at $ENV_FILE."
fi

grep "$CLONE_DIR" "$ENV_FILE" > /dev/null
if [ $? -ne 0 ]; then
	echo "source $CLONE_DIR/scripts/env_normal.sh" >> "$ENV_FILE"
	echo "export PATH=\$PATH:$CLONE_DIR/scripts" >> "$ENV_FILE"
	echo "Added PATH export to $ENV_FILE."
else
	echo "PATH export already exists in $ENV_FILE."
fi

SHELL_RC_LIST=`ls ~/.*rc 2>/dev/null`
for rc_file in $SHELL_RC_LIST; do
	grep "$ENV_FILE" "$rc_file" > /dev/null
	if [ $? -eq 0 ]; then
		echo "File $rc_file already contains source line for env.sh"
		continue
	fi

	echo "source $ENV_FILE" >> "$rc_file"
	echo "Added source line to $rc_file"
done
echo "Environment setup complete. Please restart your shell or source the modified rc files to apply changes."
