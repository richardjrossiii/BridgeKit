# First, we need to get the list of frameworks available
sdks_list=`xcodebuild -showsdks | grep -o -- "-sdk.*" | cut -d ' ' -f 2`

device_sdk=`grep -m 1 -o -- 'iphoneos\d*\.\d*' <<< $sdks_list`
simulator_sdk=`grep -m 1 -o -- 'iphonesimulator\d*\.\d*' <<< $sdks_list`

target_name='BridgeKit'

# Now that we've extracted the proper SDKs, let's build for it!
mkdir tmp/ 

# Build for the device
xcodebuild \
	-sdk $device_sdk \
	-target $target_name \
	CONFIGURATION_BUILD_DIR=tmp/ \
	>> /dev/null

# Copy the .a file to a better named one
mv 'tmp/lib'$target_name'.a' 'tmp/lib'$target_name'_iphoneos.a'

# Build for the simulator
xcodebuild \
	-sdk $simulator_sdk \
	-target $target_name \
	CONFIGURATION_BUILD_DIR=tmp/ \
	>> /dev/null

# Copy the .a file to a better named one
mv 'tmp/lib'$target_name'.a' 'tmp/lib'$target_name'_iphonesimulator.a'

# Remove the build products dir
rm -r build/

# Create our lipo library
lipo \
	-output 'tmp/lib'$target_name'_fat.a' \
	-create 'tmp/lib'$target_name'_iphoneos.a' 'tmp/lib'$target_name'_iphonesimulator.a'

# Create the .framework directory
rm -rf $target_name'.framework'
mkdir $target_name'.framework'

# Copy the binary
cp 'tmp/lib'$target_name'_fat.a' $target_name'.framework/'$target_name

# Copy the headers
cp -r 'tmp/usr/local/include' $target_name'.framework/Headers' 

rm -r tmp/

echo "Complete. Created framework at `pwd`/"$target_name".framework"
