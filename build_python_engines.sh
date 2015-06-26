#!/bin/bash

#VERSIONS=("2.7.6" "3.3.5" "3.4.0");
#MODULES=("db-sqlite3" "pysqlite" "MySQL-python")
#WSGI_STABLE_VERSION="3.4"
####VERSIONS=("3.3.5")

BUILD_DIR="/root";

function print(){
        echo     " =======================================================  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  $@  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  ================================================"
}

function compile_module(){
    local module_name="$1";
    /opt/jelastic-python${version_index_short}/bin/pip install $module_name;
}


for version in "${VERSIONS[@]}"
do
    version_index_short=$(awk -F "." '{ print $1$2}' <<< "$version")
    version_index=$(awk -F "." '{ print $1"."$2}' <<< "$version")
    cd $BUILD_DIR
    print "Downloading Python-${version}"
    [ -d "Python-${version}" ] && rm -rf "Python-${version}"
    wget "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" --no-check-certificate -O Python-${version}.tgz
    tar xfpz Python-${version}.tgz
    cd "Python-${version}";
    print "Compiling Python-${version}"
    ./configure --enable-shared --prefix="/opt/jelastic-python${version_index_short}"
    make && make install
    [ -d "/opt/jelastic-python${version_index_short}" ]  && mkdir -p "/opt/jelastic-python${version_index_short}/httpd/modules"
    print "Downloading WSGI source for  Python-${version}"
    cd $BUILD_DIR
    [ -d "mod_wsgi-${WSGI_STABLE_VERSION}" ] && rm -rf "mod_wsgi-${WSGI_STABLE_VERSION}"
    wget   "http://modwsgi.googlecode.com/files/mod_wsgi-${WSGI_STABLE_VERSION}.tar.gz" --no-check-certificate -O mod_wsgi-${WSGI_STABLE_VERSION}.tar.gz
    tar xfpz mod_wsgi-${WSGI_STABLE_VERSION}.tar.gz
    cd mod_wsgi-${WSGI_STABLE_VERSION}
    export LD_LIBRARY_PATH="/opt/jelastic-python${version_index_short}/lib"
    cp -f /opt/jelastic-python${version_index_short}/lib/*.so /usr/lib/
    ./configure --with-python=/opt/jelastic-python${version_index_short}/bin/python${version_index}
    sed -i "s/\/usr\/lib64\/httpd\/modules/\/opt\/jelastic-python${version_index_short}\/httpd\/modules/g" Makefile
    [  -f "/opt/jelastic-python${version_index_short}/bin/python${version_index}m" ] && sed -i "s/-lpython${version_index}/-lpython${version_index}m/g" Makefile
    make && make install
    [ ! -f "/opt/jelastic-python${version_index_short}/httpd/modules/mod_wsgi.so"  ] && print "error, could not compile mod_wsgi.so" && exit 1;
    print "Installing PIP for Python-${version}"
    wget "https://raw.github.com/pypa/pip/master/contrib/get-pip.py" --no-check-certificate -O get-pip.py
    /opt/jelastic-python${version_index_short}/bin/python${version_index} get-pip.py
    ls /opt/jelastic-python${version_index_short}/bin/pi*  || { print "error, could not compile PIP" && exit 1; }; 
    for module in "${MODULES[@]}"
    do
        compile_module $module
    done
    print "Packing ertefacts for Python-${version}"
    zip -r /tmp/jelastic-python${version_index_short}.zip /opt/jelastic-python${version_index_short}
done
print "All opeations compleated successfully"

