#!/bin/bash

##### A veces vemos que al cambiar de http a https dentro de wordpress, el mismo no inicia, esto se debe a que tenemos que indicarle manualmente que queremos utilizar https

echo "   ____  _____                     _       ____              _           "
echo "  / __ \| ____|___ _ __   __ _  __| | __ _|  _ \ _   _ _ __ (_) ___ __ _ "
echo " / / _\` |  _| / __| '_ \ / _\` |/ _\` |/ _\` | |_) | | | | '_ \| |/ __/ _\` |"
echo "| | (_| | |___\__ \ |_) | (_| | (_| | (_| |  _ <| |_| | | | | | (_| (_| |"
echo " \ \__,_|_____|___/ .__/ \__,_|\__,_|\__,_|_| \_\__,__|_| |_|_|\___\__,_|"
echo "  \____/          |_|                                                    "


sed -i "/That's all, stop editing! Happy publishing./a\if (\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')\n\t\$_SERVER['HTTPS']='on';" /var/www/html/wp-config.php

echo "configuración agregada a wp-config.php - ya podemos utilizar nuestro sitio en HTTPS"
echo "Gracias por utilizar el script de @EspadaRunica"
