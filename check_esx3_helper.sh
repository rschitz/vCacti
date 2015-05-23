#!/bin/sh
# VI/vSphere check_vmware_api.pl helper script v2.7 by Hypervisor.fr

export PERL_LWP_SSL_VERIFY_HOSTNAME=0

usage="$(basename $0) [vcenter] [username] [password] [action (index, query, get)] [xmlarg (clustername, dsname, podname, CPU, MEM, VMup, VMtotal, VMFS, SPOD, SPODthin, IOPS)] [target (clustername, datastorename, podname)]"

check_esx3="/var/www/cacti/scripts/check_vmware_api.pl"

vi_interval="300"
vi_timeshift="600"

if test "$1" = "" ; then
	echo $usage
	exit
elif test "$4" = "clusterindex" ; then
	perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l runtime -s listcluster|sed -e "s/([A-Z][A-Z]*)//g" -e "s/^..*: //" -e "s/|[ ]*..*$//" | sed "s/,[ ]*/#/g" | tr "#" "\n"
	exit
elif test "$4" = "datastoreindex" ; then
	perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l vmfs|sed "s/|[ ]*..*//" | tr "," "\n" | sed "s/..*[ ]*://" | awk -F"'" '{ print $2 }'
	exit
elif test "$4" = "storagepodindex" ; then
	perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l storagepod|sed "s/|[ ]*..*//" | tr "," "\n" | sed "s/..*[ ]*://" | awk -F"'" '{ print $2 }'
	exit
elif test "$4" = "query" ; then
	if test "$5" = "clustername" ; then
		for cluster in `perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l runtime -s listcluster|sed -e "s/([A-Z][A-Z]*)//g" -e "s/^..*: //" -e "s/|[ ]*..*$//" | sed "s/,[ ]*/ /g"`; do echo $cluster:$cluster; done
		exit
	elif test "$5" = "dsname" ; then
		for datastore in `perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l vmfs|sed "s/|[ ]*..*//" | tr "," "\n" | sed "s/..*[ ]*://" | awk -F"'" '{ print $2 }'` ; do echo $datastore:$datastore; done
		exit
	elif test "$5" = "podname" ; then
		for datastore in `perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l storagepod|sed "s/|[ ]*..*//" | tr "," "\n" | sed "s/..*[ ]*://" | awk -F"'" '{ print $2 }'` ; do echo $datastore:$datastore; done
		exit
	else
		echo $usage
		exit
	fi
elif test "$4" = "get" ; then
	if test "$5" = "CPU" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l $5 -s usage -o quickstats|sed "s/^..*=\([0-9][0-9.]*\)[ ]*%[ ]*|[ ]*..*$/\1/"
		exit
	elif test "$5" = "CPUMHZ" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l CPU -s usagemhz -o quickstats|awk -F"[= Mhz]" '{ print $9 }'
		exit		
	elif test "$5" = "MEM" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l $5 -s usage -o quickstats|sed "s/^..*=\([0-9][0-9.]*\)[ ]*%[ ]*|[ ]*..*$/\1/"
		exit
	elif test "$5" = "MEMMB" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l MEM -s usagemb -o quickstats|awk -F"[= MB]" '{ print $7 }'
		exit
        elif test "$5" = "QUICKMEM" ; then
                perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l MEM -o quickstats|sed "s/|[ ]*..*//"| tr ",|=" " "| awk -F" " '{ print "memusage:"$6 " overhead:"$10 " swapped:"$13 " memctl:"$16 " memzip:"$19 " private:"$22 " shared:"$25 " active:"$28}'
                exit
	elif test "$5" = "VMup" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l runtime|sed "s/^..* \([0-9][0-9]*\)\/\([0-9][0-9]*\) ..*$/\1/"
		exit
	elif test "$5" = "VMtotal" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l runtime|sed "s/^..* \([0-9][0-9]*\)\/\([0-9][0-9]*\) ..*$/\2/"
		exit
	elif test "$5" = "VMOTION" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l runtime -s VMOTION| awk -F"=" '{ print $2 }'
		exit
	elif test "$5" = "VMFSCLUSTER" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -C $6 -l storage|awk -F"[=MB]" '{ print "used:"$3 " free:"$6 }'
		exit		
	elif test "$5" = "VMFS" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l vmfs -s $6 |sed "s/^..*=*(\([0-9][0-9.]*\)%)[ ]*|[ ]*..*$/\1/"|awk '{ if (match($1,"^[.0-9]+$") != 0) print 100 - $1; else print 0; }'
		exit
	elif test "$5" = "VMFSthin" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l vmfsthin -s $6 |sed "s/^..*=*(\([0-9][0-9.]*\)%)[ ]*|[ ]*..*$/\1/"
		exit		
	elif test "$5" = "SPOD" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l storagepod -s $6 |sed "s/^..*=*(\([0-9][0-9.]*\)%)[ ]*|[ ]*..*$/\1/"|awk '{ if (match($1,"^[.0-9]+$") != 0) print 100 - $1; else print 0; }'
		exit
	elif test "$5" = "SPODthin" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l storagepodthin -s $6 |sed "s/^..*=*(\([0-9][0-9.]*\)%)[ ]*|[ ]*..*$/\1/"
		exit		
	elif test "$5" = "SIOC" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l SIOC -s $6 | awk -F"=" '{ print $3 }'| awk -F"us" '{ print $1 }'
		exit
	elif test "$5" = "IOPS" ; then
		perl $check_esx3 -S /tmp/check_$1_session.dat -D $1 -u $2 -p $3 -l IOPS -s $6 | awk -F"=" '{ print $3 }'| awk -F"iops" '{ print $1 }'
		exit		
	else
		echo $usage
		exit
	fi
else
	echo $usage
	exit
fi
