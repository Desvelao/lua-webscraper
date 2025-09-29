# Fix problem compiling with `xml` dependency
mkdir -p /usr/src/
cd /usr/src/
apk add git zlib-dev
git clone https://github.com/lubyk/xml xml_lua
cd xml_lua
git checkout REL-1.1.3
cp xml-1.1.3-1.rockspec xml-1.1.3-1.rockspec.bk
cp /app/setup/xml.rockspec /usr/src/xml_lua/xml-1.1.3-1.rockspec
luarocks install /usr/src/xml_lua/xml-1.1.3-1.rockspec

# Install library dependencies
luarocks install --only-deps /app/*.rockspec