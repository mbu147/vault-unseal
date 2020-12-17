FROM vault:latest

ADD vault-unseal.sh /vault-unseal.sh
RUN chmod a+x /vault-unseal.sh

CMD ["/bin/sh", "/vault-unseal.sh"]
