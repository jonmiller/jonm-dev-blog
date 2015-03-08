---
layout: post
title:  "Gallery 3 on Nginx"
---

A while ago I decided to convert my server over from using [Apache](https://httpd.apache.org/) to using [Nginx](http://nginx.org/). Most things I host are fairly straightforward and ported over without issue. But my [Gallery 3](http://galleryproject.org/) installation was a different story.

## PHP

The precursor for this setup is configuring PHP FastCGI for the Nginx server, which doesn't happen automatically as it does with Apache. This isn't as involved as it once was. Nginx offers a good [resource](http://wiki.nginx.org/PHPFcgiExample).

## Configuration

Most of the work for involved in getting Gallery 3 working on Nginx involves the configuration file for the server block. My full configuration is embedded below. I'm sure I haven't nailed it yet. (Much apprecation goes to this [gist](https://gist.github.com/cite/6419890).)

{% highlight nginx %}
server {

    server_name <gallery_url>;
    listen 80;

    root <path_to_gallery_installion>;

    access_log <path_to_log_locations>;
    error_log <path_to_log_locations>;

    index index.php;

    location / {

        location ~ /(index\.php/)?(.+)$ {
            try_files $uri /index.php?kohana_uri=$2&$args;
            location ~ /var/thumbs/.*/.album.jpg {
                # Direct access to album thumbs explicity allowed
            }
            location ~ /\.(ht|tpl(\.php?)|sql|inc\.php|db)$ {
                deny all;
            }
            location ~ /var/(uploads|tmp|logs) {
                deny all;
            }
            location ~ /bin {
                deny all;
            }
            location ~ /var/(albums|thumbs|resizes) {
                rewrite ^/var/(albums|thumbs|resizes)/(.*)$ /file_proxy/$2 last;
            }
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|ttf)$ {
                try_files $uri /index.php?kohana_uri=$uri&$args;
                expires 30d;
            }
        }

        location = /index.php {
            include fastcgi_params;
            fastcgi_index index.php;
            fastcgi_split_path_info ^(.+\.php)(.*)$;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            fastcgi_pass localhost:9000;
        }
    }
}
{% endhighlight %}

The PHP configuration should match up with what you set up for PHP FastCGI above.

{% highlight nginx %}
location = /index.php {
    include fastcgi_params;
    fastcgi_index index.php;
    fastcgi_split_path_info ^(.+\.php)(.*)$;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_pass localhost:9000;
}
{% endhighlight %}

The section redirects any direct requests to your photos to a file proxy, keeping your Gallery 3 security settings active.

{% highlight nginx %}
location ~ /var/(albums|thumbs|resizes) {
    rewrite ^/var/(albums|thumbs|resizes)/(.*)$ /file_proxy/$2 last;
}
{% endhighlight %}

## The Dirty Hack

The final step in getting Gallery 3 up and running, unfortunately, involves editing the Gallery 3 source in its installation location.

The file `application/config/config.php` needs to be edited to change the assignment of `$config["index_page"]` as follows:

{% highlight php %}
$config["index_page"] = "";
{% endhighlight %}

This will need to be done at every update or reinstallation of the Gallery 3 application, so I route a sed command to do it for me.

{% highlight bash %}
sed -i 's/^\$config\[\"index_page\"\] = .*$/\$config\[\"index_page\"\] = \"\";/' \
    ${GALLERY3}/application/config/config.php
{% endhighlight %}

And that should do it.
