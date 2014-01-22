lib: ./utils/config.d ./utils/ip_cipher.d
	cd ./utils; ldc2 -of=utils -lib -L-lphobos-ldc -L-lcurl config.d ip_cipher.d

host: lib ./sync/host.d 
	ldc2 -of=host.out -L-lphobos-ldc -L-lcurl -L./utils/libutils.a ./sync/host.d

client: ./sync/client.d lib
	ldc2 -of=client.out -L-lphobos-ldc -L-lcurl -L./utils/libutils.a ./sync/client.d

host_no_cipher: lib ./sync/host.d
	ldc2 -of=host.out -L-lphobos-ldc -L-lcurl -L./utils/libutils.a ./sync_no_cipher/host.d

client_no_cipher: ./sync/client.d lib
	ldc2 -of=client.out -L-lphobos-ldc -L-lcurl -L./utils/libutils.a ./sync/client.d

all: host client
	rm *.o
	
all_no_cipher: host_no_cipher client_no_cipher
	rm *.o

clean:
	rm *.out
	rm *.o
