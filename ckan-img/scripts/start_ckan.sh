#!/bin/bash

# ----------------------------------------------------- # 
#  Finalizado el Build del contenedor en "run-mode"     #
#  debemos hacer algunas cosas para que todo funcione   #
#  correctamente.                                       #
# ----------------------------------------------------- #

APACHE2_WSGI=$CKAN_CONFIG/apache.wsgi
nginx &
service apache2 restart;
service redis-server restart;
service rabbitmq-server restart;
service postfix restart;

# Creamos contexto para CKAN
/bin/bash $CKAN_INIT/.make_conf.sh
mconf=$?

# Inicializamos la Base de datos e incluso, Solr.
/bin/bash $CKAN_INIT/.init_db.sh
idb=$?


exit_code=$(($mconf + $idb))

# Ambos commandos anteriores, fueron exitosos?
if [ "$exit_code" -eq "0" ] ; then

	# Considerando que CKAN/data va a ser un volumen externo, corrijo permisos
	chown www-data:www-data $CKAN_DATA $CKAN_DIST_MEDIA $CKAN_DIST_CONFIG
	chmod u+rwx $CKAN_DATA $CKAN_DIST_MEDIA $CKAN_DIST_CONFIG
	
	service apache2 restart;
	service nginx reload;
	# Conectamos los logs de ckan con la salida de "docker logs"
	tail  -f /var/log/apache/ckan_default.error.log
	

else
	# Ok.. el mundo ya no es un lugar amigable!
	echo "-------------------------------------------"
	echo "  Ooops! hubo un problema.. :( " 
	echo "-------------------------------------------"
fi