# Computing Curricula Generator 3.0

Curricula generator for Computer Science related careers (CS, IS, Technical CS, etc)

## Requirements

Tested on:
```
Ubuntu 16.04 || Ubuntu 18.04 || Ubuntu 20.04 || macOS Catalina
Perl v5.30.0
TeX v3.14159265
```

## Setup

### **Ubuntu** (outdated, go to Docker section)

#### Install required packages:

```
sudo apt-get install texlive-full texlive-science texlive-latex-extra texlive-bibtex-extra texlive-lang-spanish gv inkscape csh libcarp-assert-perl okular chromium-browser graphviz dot2tex texlive-pstricks biber kile ps2eps latex2html build-essential pdftk mupdf mupdf-tools libnumber-bytes-human-perl
```

#### Install required PERL modules:
```
sudo cpan install Clone
sudo cpan install CAM::PDF
sudo cpan install Switch
```

#### Adding rule to prevent convert error:

Error:
```
convert-im6.q16: attempt to perform an operation not allowed by the security policy `PS' @ error/constitute.c/IsCoderAuthorized/408.
```
Solution:

Change or add this line:
```
<policy domain="coder" rights="none" pattern="PDF" />
```
to
```
<policy domain="coder" rights="read | write" pattern="PDF" />
```


#### **Only for Ubuntu 18.04 or higher**

`__pdftk__ package not found`

Solution:

```
sudo add-apt-repository ppa:malteworld/ppa
sudo apt update
sudo apt install pdftk
```
Export custom PERL libraries:
```
export PERL5LIB=/home/$USER/Curricula/Curricula.Master/scripts/
```

### **Docker**

Use case for Docker is to run the generator on any OS without installing any dependencies.

1. Build or rebuild container: `docker-compose build`
1. Start container: `docker-compose up -d`

Shutdown or remove: 
1. Stop container: `docker-compose stop`
1. Remove container: `docker-compose down`


## Generar Curricula

1. Revisar la configuración actual de la institución.
1. Ejecutar los siguientes scripts:
    * Genera scripts para CS-UCSP en Curricula.out
        ```bash
        docker exec -i curricula-curricula-1 bash -c "cd /app/Curricula.Master && ./scripts/gen-scripts.pl Peru-CS-UCSP" 
        ``` 
    * Genera la curricula (Y) en .pdf, pero no la parte HTML (N), ni sílabos (N)
        ```bash
        docker exec -i curricula-curricula-1 bash -c "cd /app/Curricula.Master && ./../Curricula.out/Peru/CS-UCSP/cycle/2020-I/Plan2016/scripts/compile1institucion.sh y n n"
        ``` 

1. Imprimir los archivos en `Curricula.out/pdfs`, distribuir syllabi y descansar hasta el próximo semestre!"

## Localizaciones
Directorios y archivos importantes a considerar:

### Curricula.in/
1. Macros: ./Curricula.in/lang/{Lenguaje}/CS.sty/bok-macros.sty
1. Sílabos: ./Curricula.in/lang/{Lenguaje}/cycle/{ciclo}/Syllabi/{Área}/{Programa}
1. Dependencias (cursos): ./Curricula.in/lang/Espanol/CS.tex/CS201X-dependencies.tex
1. Lista de instituciones: ./Curricula.in/institutions-list.txt

### Curricula.Master/
1. Scripts generales: ./Curricula.Master/scripts
1. Librerías propias: ./Curricula.Master/scripts/Lib

### Curricula.out/ (Generado)
1. Curricula y Libros: ./Curricula.out/pdfs

### Useful commands
1. Clean Repo:
    ```bash
    git clean -dfx
    ```

## Fuentes
CS2013: http://ai.stanford.edu/users/sahami/CS2013/final-draft/CS2013-final-report.pdf

## Colaborar
Cualquier ayuda a este proyecto o algún bug no resuelto reportarlo!
Realizar Pull request para colaborar o presentar un Issue con los errores!

Gracias!
