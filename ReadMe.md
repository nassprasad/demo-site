<img width="1215" height="476" alt="image" src="https://github.com/user-attachments/assets/d284f08c-c791-4ec2-8dbd-df59f749ece3" />


ot@upload-services:~# hostname
upload-services
root@upload-services:~# uptime
 12:47:55 up 5 min,  1 user,  load average: 0.02, 0.14, 0.08
root@upload-services:~#
root@upload-services:~# systemctl status   nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-09-28 12:47:17 EDT; 43s ago
       Docs: man:nginx(8)
    Process: 965 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 967 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 968 (nginx)
      Tasks: 2 (limit: 1055)
     Memory: 2.5M (peak: 2.8M)
        CPU: 48ms
     CGroup: /system.slice/nginx.service
             ├─968 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             └─969 "nginx: worker process"

Sep 28 12:47:16 upload-services systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Sep 28 12:47:17 upload-services systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
root@upload-services:~# ps -ef | grep nginx
root         968       1  0 12:47 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data     969     968  0 12:47 ?        00:00:00 nginx: worker process
root         984     933  0 12:48 pts/1    00:00:00 grep --color=auto nginx
root@upload-services:~#

