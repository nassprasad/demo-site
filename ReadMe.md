
upload-services ( Sharing )  Nginx
ssh siva@50.116.63.214


root@upload-services:~# ps -ef | grep nginx
root     1898821       1  0 Sep11 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data 1898822 1898821  0 Sep11 ?        00:11:20 nginx: worker process
root     1961199 1961186  0 12:21 pts/5    00:00:00 grep --color=auto nginx



systemctl status  nginx
------------------------------------------------------------


quotesim5  ( Simulator ) Nginx
ssh siva@45.33.95.195


root@quotesim5:~# ps -ef | grep nginx
root     2200882       1  0 Sep11 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data 2200883 2200882  0 Sep11 ?        00:18:55 nginx: worker process
www-data 2200884 2200882  0 Sep11 ?        00:18:39 nginx: worker process
root     2268047 2268030  0 12:20 pts/4    00:00:00 grep --color=auto nginx



 systemctl status nginx

------------------------------------------------------------

connect7   				Apache 
ssh siva@66.228.58.222

siva@localhost:~$ ps -ef | grep apache
www-data  3429 11836  0 06:25 ?        00:03:26 /usr/sbin/apache2 -k start
www-data  3430 11836  0 06:25 ?        00:01:34 /usr/sbin/apache2 -k start
www-data  3629 11836  0 09:16 ?        00:00:09 /usr/sbin/apache2 -k start
siva      4810  4762  0 16:18 pts/0    00:00:00 grep --color=auto apache
root     11836     1  0 Jun03 ?        00:08:21 /usr/sbin/apache2 -k start


systemctl status apache2

