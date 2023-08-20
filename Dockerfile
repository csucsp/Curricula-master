FROM texlive/texlive:latest

# installing apt packages
RUN apt-get update
RUN apt-get install -y \
  gcc \
  csh \
  mupdf mupdf-tools \
  imagemagick \
  dot2tex latex2html \
  texlive-lang-spanish texlive-pstricks \
  texlive-bibtex-extra biber

# installing Perl Modules
RUN cpan \
  Carp::Assert \
  Array::Utils \
  Number::Bytes::Human \
  PDF::API2 \
  File::Slurp \
  Switch

RUN apt-get clean

# disables security of Ghostscript: https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
