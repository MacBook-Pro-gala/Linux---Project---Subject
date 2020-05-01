
#!/bin/bash
#删除90天前数据
 
find /nfsfile/backup -mtime +90 -name "*.*" -exec rm -rf {} \;
 
mysqldump -uroot -p"liuyuhan" --single-transaction wordpress > /nfsfile/backup/wordpress_`date +%Y%m%d`.dump
