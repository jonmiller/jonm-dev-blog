#! /bin/bash

jekyll build && rsync -avz --delete _site/ jonamiller.com:/home/jonm/public-html/default/public/jekyll
