FROM centos:7
MAINTAINER muyu.zhouyu@outlook.com

# 安装依赖
RUN yum makecache
RUN yum -y install \
        gcc gcc-c++ \
        make libtool \
        autoconf  automake\
        patch unzip \
        libxml2 libxml2-devel \
        ncurses ncurses-devel \
        libtool-ltdl-devel libtool-ltdl \
        libmcrypt libmcrypt-devel \
        libpng libpng-devel libjpeg-devel \
        openssl openssl-devel \
        curl curl-devel \
        libxml2 libxml2-devel \
        libaio*

# 创建源码包存放目录
RUN mkdir -p /data/package/nmp

# 复制本地包到容器里
COPY package_src/zlib-1.2.3.tar.gz /data/package/nmp/
COPY package_src/php-5.3.29.tar.gz /data/package/nmp/
COPY package_src/pcre-8.12.tar.gz /data/package/nmp/
COPY package_src/libpng-1.2.50.tar.gz /data/package/nmp/
COPY package_src/libmcrypt-2.5.8.tar.gz /data/package/nmp/
COPY package_src/libiconv-1.13.1.tar.gz /data/package/nmp/
COPY package_src/libevent-1.4.14b.tar.gz /data/package/nmp/
COPY package_src/jpegsrc.v6b.tar.gz /data/package/nmp/
COPY package_src/freetype-2.1.10.tar.gz /data/package/nmp/
COPY package_src/config-php.zip /data/package/nmp/
COPY package_src/nginx-1.16.1.tar.gz /data/package/nmp/

# 安装nginx
RUN cd /data/package/nmp && \
       tar zxvf nginx-1.16.1.tar.gz && \
       mkdir -p /data/server/nginx-1.16.1 && \
       ln -s /data/server/nginx-1.16.1 /data/server/nginx && \
       cd nginx-1.16.1 && \
       ./configure --user=www \
                --group=www \
                --prefix=/data/server/nginx \
                --with-http_stub_status_module \
                --without-http-cache \
                --with-http_ssl_module \
                --with-http_gzip_static_module && \
       make && make install && \
       chmod 755 /data/server/nginx/sbin/nginx && cp /data/server/nginx/sbin/nginx /etc/init.d/ && \
       chmod +x /etc/init.d/nginx

# 拷贝nginx.conf, 以便于开箱即用
COPY nginx.conf /data/server/nginx/conf/

# 安装libiconv库
RUN cd /data/package/nmp && \
        tar zxvf libiconv-1.13.1.tar.gz && \
        cd libiconv-1.13.1 && \
        ./configure --prefix=/usr/local && \
        make && \
        make install

# 安装zlib库
RUN cd /data/package/nmp && \
        tar zxvf zlib-1.2.3.tar.gz && \
        cd zlib-1.2.3 && \
        ./configure && \
        make && \
        make install

# 安装freetype库
RUN cd /data/package/nmp && \
        tar zxvf freetype-2.1.10.tar.gz && \
        cd freetype-2.1.10 && \
        ./configure --prefix=/usr/local/freetype.2.1.10 && \
        make && \
        make install

# 安装libpng库
RUN cd /data/package/nmp && \
        tar zxvf libpng-1.2.50.tar.gz && \
        cd libpng-1.2.50 && \
        ./configure --prefix=/usr/local/libpng.1.2.50 && \
        make && \
        make install

# 安装libevent库
RUN cd /data/package/nmp && \
        tar zxvf libevent-1.4.14b.tar.gz && \
        cd libevent-1.4.14b && \
        ./configure && \
        make && \
        make install
    
# 安装libmcrypt库
RUN cd /data/package/nmp && \
        tar zxvf libmcrypt-2.5.8.tar.gz && \
        cd libmcrypt-2.5.8 && \
        ./configure --disable-posix-threads && \
        make && \
        make install && \
        /sbin/ldconfig && \
        cd libltdl/ && \
        ./configure --enable-ltdl-install && \
        make && \
        make install

#  安装pcre库
RUN cd /data/package/nmp && \
        tar zxvf pcre-8.12.tar.gz && \
        cd pcre-8.12 && \
        ./configure && \
        make && \
        make install

#  安装jpeg.6库
RUN mkdir -p /usr/local/jpeg.6/include
RUN mkdir /usr/local/jpeg.6/lib
RUN mkdir /usr/local/jpeg.6/bin
RUN mkdir -p /usr/local/jpeg.6/man/man1
RUN cd /data/package/nmp && \
        tar zxvf jpegsrc.v6b.tar.gz && \
        cd jpeg-6b && \
        cp /usr/share/libtool/config/config.sub . && \
        cp /usr/share/libtool/config/config.guess . && \
        ./configure --prefix=/usr/local/jpeg.6 --enable-shared --enable-static && \
        make && \
        make install-lib && \
        make install
    
# 设置环境
RUN cd /usr/local/src && \
        touch /etc/ld.so.conf.d/usrlib.conf && \
        echo "/usr/local/lib" > /etc/ld.so.conf.d/usrlib.conf && \
        /sbin/ldconfig

# 创建一些基础目录
RUN mkdir -p /data/server && \
        mkdir -p /data/log && \
        mkdir -p /data/www && \
        mkdir -p /data/www/bbc && \
        mkdir -p /data/log/php && \
        mkdir -p /data/log/nginx && \
        mkdir -p /data/backup

# 创建用户
RUN groupadd www && \
        useradd  -g www -d /data/www -m www

# 权限授予
RUN chown -R www:www /data/www && \
        chown -R www:www /data/log && \
        chmod -R 775 /data/www && \
        chmod -R 775 /data/log

# 解压缩PHP
RUN cd /data/package/nmp && \
        ls && \
        tar zxvf php-5.3.29.tar.gz

# 配置目录
RUN mkdir -p /data/server/php-5.3.29
RUN ln -s /data/server/php-5.3.29 /data/server/php

# 编译PHP
RUN cd /data/package/nmp/php-5.3.29 && ./configure --prefix=/data/server/php \
        --with-config-file-path=/data/server/php/etc \
        --with-mysql=mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --enable-fpm \
        --enable-fastcgi \
        --enable-static \
        --enable-inline-optimization \
        --enable-sockets \
        --enable-wddx \
        --enable-zip \
        --enable-calendar \
        --enable-bcmath \
        --enable-soap \
        --with-zlib \
        --with-iconv \
        --with-gd \
        --with-xmlrpc \
        --enable-mbstring \
        --without-sqlite \
        --with-curl \
        --enable-ftp \
        --with-mcrypt  \
        --with-freetype-dir=/usr/local/freetype.2.1.10 \
        --with-jpeg-dir=/usr/local/jpeg.6 \
        --with-png-dir=/usr/local/libpng.1.2.50 \
        --disable-ipv6 \
        --disable-debug \
        --with-openssl \
        --disable-maintainer-zts \
        --disable-safe-mode \
        --disable-fileinfo && \
        make ZEND_EXTRA_LIBS='-liconv' -j8 && \
        make install

# 复制PHP配置文件
RUN cd /data/package/nmp/ && unzip config-php.zip
RUN cp -fR /data/package/nmp/config-php/* /data/server/php/etc/

# 设置PHP启动文件
RUN install -v -m755 /data/package/nmp/php-5.3.29/sapi/fpm/init.d.php-fpm  /etc/init.d/php-fpm

# 配置PHP环境变量
RUN echo 'export PATH=$PATH:/data/server/php/sbin:/data/server/php/bin' >> /etc/profile
RUN export PATH=$PATH:/data/server/php/sbin:/data/server/php/bin

# 后台启动nginx
RUN /etc/init.d/nginx

EXPOSE 9000
CMD /data/server/php/sbin/php-fpm -F
