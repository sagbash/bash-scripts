#!/bin/bash
#Sendmail loglarinin logrotate ile işlendikten sonraki halinden log okumak için yazmış olduğum bash script
#set -x
saveDir=/root/sagbas/maillogOutputFiles

#Gerekli degiskenlerin input olarak alinmasi
echo
read -p 'Kullanici adini giriniz (ornek: sagbas20) : ' username
read -p 'Son kac gunluk mail goruntulenecek (bugun 0, dun 1): ' dayCount
echo
#Örneğin son 90 gunun logu tutuluyorsa kontrol, if fails output to stderr
if [ $dayCount -lt 0 ] || [ $dayCount -gt 91 ]; then echo "$0 scriptinde gun araligi hatali (0-90 olarak  giriniz)" >&2
exit 1
fi

#Eski dosyalar varsa temizle
echo "Mail id dosyalari temizleniyor"
rm -f ${saveDir}/${username}.*
echo 'DONE'
echo "Output dosyalari temizleniyor"
rm -f ${saveDir}/out_${username}.*
echo -e 'DONE\n'

#Mail loglarin alici adresi eslesmesine  gore smtp idlerinin ilgili dosyalarda toplanmasi
echo 'Mail loglar okunuyor'
for (( i=0 ; i<=$dayCount ; i++))
do
if [ $i -eq 0 ];
        then
        grep "$username" /var/log/maillog | grep ": to=" | awk -F " " '{print $6}' | sed s/://g > $saveDir/$username.0
        echo 'maillog DONE'
    elif [ $i -eq 1 ];
        then
        grep "$username" /var/log/maillog.1 | grep ": to=" | awk -F " " '{print $6}' | sed s/://g > $saveDir/$username.1
        echo 'maillog.1 DONE'
    elif [ $dayCount -lt 91 ] && [ $dayCount -gt 1 ];
        then
        echo -ne "maillog.{2..$i}.gz      \r"
        zgrep "$username" /var/log/maillog.$i.gz | grep ": to=" | awk -F " " '{print $6}' | sed s/://g > $saveDir/$username.$i
        #if [ $i -eq $dayCount ];then
        echo -ne "maillog.{2..$i}.gz DONE\r"
        sleep 0.2
        #fi
fi
done
echo
echo 'ALL DONE'
#Toplanan log dosyalarinin okunarak smtp id bulunan satirlardaki from adreslerinin cekilmesi
echo "Dosyalar okundu, ${username}'e mail gonderen adresler bulunuyor."
for x in $(ls -v $saveDir/$username.*)
do
if [ -s "$x" ]; then
i="${x##${saveDir}/${username}.}"
filterFile=${saveDir}/${username}.$i
echo "Reading FILE ${x##${saveDir}/}";

#echo $i
#Dosya bos degilse smtp id yazdir, yazdirilan verileri for loop ile don

#for line in $(cat $x)
#do
#echo $line
if [ $i -gt 1 ] && [ $i -lt 91 ]; then echo "$line $(zcat /var/log/maillog.$i.gz | grep -f $filterFile |  grep -oE 'from=<[^>]*>')" >> ${saveDir}/out_$username.$i
elif [ $i -eq 1 ]; then echo "$line $(cat /var/log/maillog.1 | grep -f $filterFile |  grep -oE 'from=<[^>]*>')" >> ${saveDir}/out_$username.1
elif [ $i -eq 0 ]; then echo "$line $(cat /var/log/maillog | grep -f $filterFile |  grep -oE 'from=<[^>]*>')" >> ${saveDir}/out_$username.0
fi
#done
fi
done

echo "Islem basariyla tamamlandi. Output dosyalari ${saveDir}/ dizininde ${username} ve out_${username} dosyalarinda bulunmaktadir."

exit 0
