#!/bin/bash

##### A veces vemos que al cambiar de http a https dentro de wordpress, el mismo no inicia, esto se debe a que tenemos que indicarle manualmente que queremos utilizar https

echo "   ____       _                         _                          ";
echo "  / __ \  ___| |__  _ __ ___   ___   __| |_ __ ___   __ _ _____  __";
echo " / / _\` |/ __| '_ \| '_ \` _ \ / _ \ / _\` | '_ \` _ \ / _\` / __\ \/ /";
echo "| | (_| | (__| | | | | | | | | (_) | (_| | | | | | | (_| \__ \>  < ";
echo " \ \__,_|\___|_| |_|_| |_| |_|\___/ \__,_|_| |_| |_|\__,_|___/_/\_\ ";
echo "  \____/                                                           ";
echo "En Dios confiamos | In God we trust"
echo "\n"


sed -i "/That's all, stop editing! Happy publishing./a\if (\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https')\n\t\$_SERVER['HTTPS']='on';" /var/www/html/wp-config.php

SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/html/wp-config.php

echo "configuración agregada a wp-config.php - ya podemos utilizar nuestro sitio en HTTPS"
echo "Gracias por utilizar el script de @EspadaRunica"
