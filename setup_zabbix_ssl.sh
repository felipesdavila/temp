#!/bin/bash

# Variáveis
DOMAIN="zabbix.local"
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"
APACHE_CONF="/etc/apache2/sites-available/zabbix-ssl.conf"

# Atualiza pacotes e instala Apache + SSL
echo "[INFO] Instalando Apache e módulos SSL..."
apt update && apt install -y apache2 openssl

# Ativa módulo SSL no Apache
a2enmod ssl

# Cria diretórios se não existirem
mkdir -p $CERT_DIR $KEY_DIR

# Gera chave privada e certificado autoassinado
echo "[INFO] Gerando certificado SSL autoassinado..."
openssl genrsa -out $KEY_DIR/zabbix.key 2048
openssl req -new -x509 -key $KEY_DIR/zabbix.key -out $CERT_DIR/zabbix.crt -days 365 -subj "/C=BR/ST=Santa Catarina/L=Concordia/O=MinhaEmpresa/CN=$DOMAIN"

# Cria configuração do VirtualHost para HTTPS
echo "[INFO] Configurando VirtualHost SSL..."
cat <<EOF > $APACHE_CONF
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot /usr/share/zabbix

    SSLEngine on
    SSLCertificateFile $CERT_DIR/zabbix.crt
    SSLCertificateKeyFile $KEY_DIR/zabbix.key

    <Directory /usr/share/zabbix>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Ativa site SSL e reinicia Apache
a2ensite zabbix-ssl.conf
systemctl restart apache2

echo "[INFO] Configuração concluída!"
echo "Acesse: https://$DOMAIN"
