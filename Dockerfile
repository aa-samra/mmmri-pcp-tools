FROM vistalab/fsl-v5.0

RUN apt-get clean
RUN apt-get -y update
RUN apt-get install -y --no-install-recommends\
	zip unzip pigz jq moreutils time wget inotify-tools vim curl parallel 

RUN apt-get -y -qq install libblas-dev liblapack-dev libatlas-base-dev gfortran python3-scipy

RUN wget https://repo.anaconda.com/archive/Anaconda3-2023.07-1-Linux-x86_64.sh -O anaconda.sh
RUN bash anaconda.sh -b -p /opt/anaconda && rm anaconda.sh

RUN mkdir code

COPY process_dwi.sh /code/process_dwi.sh
COPY process_fmri.sh /code/process_fmri.sh
COPY fix_issues.sh /code/fix_issues.sh

RUN chmod +x /code/*

RUN ./code/fix_issues.sh


