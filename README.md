# CTF-1
Capture the flag donde se trabaja la enumeración y fingerprinting, conexión FTP, php, reverse shell, netcat, escalada de privilegios... 

## Objetivo

Explicar la realización del _Capture the flag_ siguiente dentro del mundo educativo. Se preteneden conseguir dos archivos (_flags_), uno dentro del entorno del usuario básico y el otro en el entorno _root_. Para ellos, se deberá penetrar en la máquina, pasar al usuario básico y realizar una escalada de privilegios.

## Que hemos aprendido?

- Realizar fingerprinting y enumeración de puertos y enumeración web.
- Realizar *reverse shell* con *php*.
- Poner puertos en escucha.
- Escalada de privilegios.

## Herramientas utilizadas

- Kali Linux.
- Enumeración: nmap, WFUZZ.
- Penetración: código php de 'Pentest Monkey', netcat, lenguaje bash, web 'exploit-database'. 

## Steps

### Enumeración y fingerprinting

La máquina a vulnerar está desplegada dentro de un Docker, para encontrar este, desde el terminal de Kali, se busca su direción IP con el comando <code>ipconfig</code>. En la respuesta se averigua que su dirección IP es la 172.17.0.1, por lo que la máquina víctima debe estar en la red 172.17.0.X. Utilizando la herramienta __nmap__ puedo hacer un barrido para encontrar el host que estoy buscando, para hacerlo más rápido no compruebo puertos.  

<code>nmap -sn 172.17.0/24</code>  

![427138515-a9e766f5-48f7-4510-8ca1-05af72817794](https://github.com/user-attachments/assets/383ace90-df56-4fbd-b715-5f5f726caf92)

Ya tengo localizada la máquina en la dirección 172.17.0.2, ahora con la ayuda de __nmap__ se buscan los puertos de la máquina que se encuentran abiertos y las versiones que corren en ellos. Le indico que no haga descubrimiento de hosts mediante ‘-Pn’. Además, utilizo el script ‘default’ que viene con nmap para que me muestre las vulnerabilidades que pueda encontrar.  

<code>nmap -p- -Pn -sV -O 172.17.0.2 -sC</code>  

![427141463-8c876a8a-464d-48a5-9298-e522cc7764ee](https://github.com/user-attachments/assets/4621faeb-9571-4a84-a347-830406e729f3)

El comando nos devuelve 3 puertos TCPs abiertos:
- En el puerto 21 corre la versión vsftpd 3.0.3 del servicio FTP.
- En el puerto 22 corre la versión Openssh 7.6p1 del servicio SSH en un sistema Ubuntu.
- En el puerto 80 corre la versión Apache httpd 2.4.29 del servicio HTTP en un sistema Ubuntu.

Los scripts muestran una serie de vulnerabilidades entre la que destaca el hecho de poder iniciar sesión vía FTP con una cuenta ‘anonymous’, por lo que no será necesaria una contraseña. Una vez dentro, encuentro el directorio ‘html’ y dentro de este, dos archivos: ‘index.php’ e ‘index.html.bak’. Estos archivos hacen referencia al servidor de Apache que hay montado en el puerto 80. Puesto que tengo acceso a esta carpeta y permisos de escritura, subiré un archivo ‘php’ con una reverse shell para poder tomar el control de la máquina.  
Para la enumeración web se utiliza la herramiente __WFUZZ__ que econtrará los posibles archivos y directorios que pertenezcan a la IP. Con la opción ‘-c’ se muestran los valores con diferentes colores, con ‘-hc 404’ evito que salgan por pantalla todos aquellos intentos que no han encontrado nada. El parámetro ‘-t’ sirve para indicar la velocidad que ejecuta el comando, he decidido ponerle 1 para que analice todos los posibles ficheros con el inconveniente de tardar más. El parámetro ‘-w’ indica la lista a partir de la cual se va a hacer el fuzzing y el parámetro ‘-u’ es para la URL de la página destino. Añadiendo la palabra FUZZ al final, indico que la palabra de la lista que analiza, la busque en esa posición de la url.  

<code>wfuzz -c --hc 404 -t 1 -w /usr/share/seclists/Discovery/Web-Content/raft-small-files.txt -u http://172.17.0.2/FUZZ</code>  

![427168994-9e23fdc9-fc67-41f4-8fb6-e99e683ececb](https://github.com/user-attachments/assets/f49331ae-24e6-4ffc-8009-b237acb12157)

Kali contiene una serie de listas (diccionarios) con los nomber más típicos de archivos o directorios web, en la imagen se prueba con archivos. De entre los archivos devueltos, los alcanzables son ‘index.php’ y ‘index.html.bak’. Confirmando lo encontrado por la vía FTP.

### Vulnerabilidades explotadas
Una vez hecha la enumeración, me dispongo a explotar la vulnerabilidad FTP encontrada, donde no se pide contraseña alguna para iniciar sesión con el usuario ‘anonymous’. Me dirijo al directorio /html y utilizo el comando ‘mget’ para descargar el ‘index.php’ que a efectos prácticos no es muy útil, contiene el mensaje que se muestra en la dirección IP de la máquina.  

![427514869-9b0c3aca-39b1-482e-a5ad-2d04444f2e66](https://github.com/user-attachments/assets/321914e1-f60c-48dd-88ef-958f7eee6181)

<code>ftp 172.17.0.2</code>  
<code>cd html</code>  
<code>mget index.php</code>  

Opto por subir vía FTP un archivo ‘php’ con el ataque y alojarlo en la misma carpeta /html donde se encuentran los otros archivos. El ataque consiste en una _reverse shell_ escrita en *php* obtenida de la plataforma de github, subida por [pentestmonkey](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php). Modifico la dirección IP en el código por la mía (10.0.2.15) y el puerto deseado (1234 por defecto), el resto lo dejo igual. Para subir este archivo, debo estar situado en el directorio donde lo tengo guardado ‘/home/kali’ y una vez conectado vía ftp, voy al directorio donde lo quiero guardar ‘/html’. El comando utilizado es ‘put’ seguido del nombre del archivo.  

<code>put php-reverse-shell.php</code>  

Lo siguiente es, desde mi terminal, poner el puerto especificado en el script en escucha (1234). Para hacer esto hago uso de la herramienta **netcat**, le indico la opción de verbosidad y que busque direcciones IP numéricas.  

<code>nc -lvnp 1234</code>  

Por último, me dirijo a la dirección *url* del archivo (http://172.17.0.2/php-reverse-shell.php) y espero que se produzca la conexión. Al conectarnos, puedo ver qué usuario soy con un ‘whoami’ que me devuelve ‘www-data’. Además, se observa que pertenezco al grupo de mismo nombre, ‘www-data’. Este es el típico usuario que se obtiene al acceder vía web.

![427516314-1fedb1bb-98dc-42bc-8bf2-305f47898d5d](https://github.com/user-attachments/assets/0c79c87e-6701-4cd3-803f-a60e1ed377d6)

Una vez dentro sólo debo buscarla *flag*, la cual encuentro en el directorio '/home/hacker/'.  
**Flag**: 244cdf401e667cca77b8228066096985.  

![427518574-dbd4ffa4-ee6c-4fc1-bc14-0c9b12819537](https://github.com/user-attachments/assets/e4653076-ac0f-489b-9b16-4711d87d9005)

Para conseguir la escalada de privilegios, me fijo en que antriormente he descubierto al existencia del usuario 'hacker'. Así pues, voy a buscar procesos lanzados por este usuario o que sea mencionado.  

<code>ps aux | grep hacker</code>  

Como respuesta, obtengo un proceso ejecutado por el usuario *root* en estado de espera, el cual consiste en un script llamado ‘myhacker.sh’ y al que parece que se le pasa una contraseña ‘tefeme_86_pass’.
Intento **pivotar** al usuario hacker probando con esta contraseña y después de conseguirlo, lo compruebo mediante el comando ‘id’.

![427528819-4a47603f-e039-4a50-9422-fbf93042874c](https://github.com/user-attachments/assets/ae914b8f-a229-4e4f-85ef-b9ae2b797ae6)

El siguiente paso es buscar archivos, desde el directorio raíz, con el **bit SUID** activado que permitan ser ejecutados con permisos *root* (find / -perm -4000). Además, los mensajes erróneos que devuelva, los mandamos a la dirección '/dev/null' para que no se muestren por pantalla (2>/dev/null). Como respuesta aparecen una serie de binarios  de entre los cuales, me llama la atención '/usr/local/lib/sudo' pues no se encuentra en '/usr/bin', como cabría esperar.

<code>find / -perm -4000 2>/dev/null</code>

Haciendo una búsqueda por la web [exploit-database](https://www.exploit-db.com/exploits/47502), encuentro una vulnerabilidad que fue resuelta a partir de la versión 28. Para explotarla voy a abrir una shell con un usuario inexistente, indicándole el uid -1; lo cual devolverá un 0 y lo confundirá con el usuario *root*.

<code>sudo -u#-1 /bin/bash</code>

![427654438-64cc9af0-e429-4b07-84af-e68e1d1e62dd](https://github.com/user-attachments/assets/a8620f84-59cb-49f6-92e6-2f6f2be4a425)

Una vez soy usuario *root*, puedo dirigirme a su directorio '/root' y encontrar la segunda *flag*.

![427657084-6ec0d4b1-335f-4d86-9e8d-b4bb3f033649](https://github.com/user-attachments/assets/bc748004-0c88-4ce4-88a6-5a0b7fd45dcb)

**Flag**: 648d390c021ce7cfde2f95ea3fcd71ec.
