# docker build --no-cache -t salesian_app .
# docker run --name=salesian_app --user shiny --rm -p 80:3838 salesian_app

FROM rocker/shiny-verse:latest

MAINTAINER Brent Schneeman "schneeman@gmail.com"

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libudunits2-dev \
    libv8-3.14-dev

# basic shiny functionality
RUN R -e "install.packages(c('scales', 'ggthemes', 'units', 'devtools', 'here'), repos='https://cran.rstudio.com/')"

# install devtools related stuff
# RUN R -e "devtools::install_github('sailthru/tidyjson')"


# copy the app to the image
#
COPY . /srv/shiny-server/

RUN chmod -R +r /srv/shiny-server/

EXPOSE 80

CMD ["/usr/bin/shiny-server.sh"] 