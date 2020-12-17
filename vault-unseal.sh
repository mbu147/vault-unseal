#!/bin/bash

VAULT_KEYS="$VAULT_UNSEAL_KEY_1 $VAULT_UNSEAL_KEY_2 $VAULT_UNSEAL_KEY_3 $VAULT_UNSEAL_KEY_4 $VAULT_UNSEAL_KEY_5 $VAULT_UNSEAL_KEY_6 $VAULT_UNSEAL_KEY_7 $VAULT_UNSEAL_KEY_8 $VAULT_UNSEAL_KEY_9 $VAULT_UNSEAL_KEY_10 $VAULT_UNSEAL_KEY_11 $VAULT_UNSEAL_KEY_12 $VAULT_UNSEAL_KEY_13 $VAULT_UNSEAL_KEY_14 $VAULT_UNSEAL_KEY_15"

VAULT_MAX_KEYS=$VAULT_MAX_KEYS

i=0
while :
do
    for k in $VAULT_KEYS; do
        # https://github.com/hashicorp/vault/blob/c44f1c9817955d4c7cd5822a19fb492e1c2d0c54/command/status.go#L107
        # code reflects the seal status (0 unsealed, 2 sealed, 1 error).
        i=$((i+1))
        if [[ $i -gt ${VAULT_MAX_KEYS} ]]; then i=1; fi
        vault status 1> /dev/null 2>/dev/null
        st=$?

        if [ $st -eq 0 ]; then
            echo "vault is unsealed"
            break
        elif [ $st -eq 2 ]; then
            echo "vault is sealed"
            echo "unsealing with key $i"

            if [ -z "$k" ]; then
                echo "ran out of vault uneal keys at $i (VAULT_UNSEAL_KEY_$i is missing). terminating..."
                break
            fi

            vault operator unseal "$k" > /dev/null
            code=$?
            if [ $? -ne 0 ] ; then
                echo "unseal returned a bad exit code ($code). terminating..."
                break
            fi
            sleep 5

        elif [ $st -eq 1 ]; then
            echo "vault returned an error"
            echo "maybe no container available on http://vault-sealed:8200 cause every one already unsealed?"
            break
        fi
    done
	sleep 2
done
