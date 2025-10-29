* هذه بعض التعليقات على الملف المستخدم 

docker-compose.yaml

<div dir='rtl'>

## 1- Volume

*  إذا كنت تنشأ Volume من خلال docker compose فإنه سينشأه تحت نفس المسار مع إضافة اسم المشروع 
```bash
# path for the project that contatin the yaml for compose
ls -l /home/hafez/containers/jenk-sona-nex/docker-compose.yml


# Volumes from yaml file 
grep -A1  "volumes:" /home/hafez/containers/jenk-sona-nex/docker-compose.yml
    volumes:
      - jenkins_data:/var/jenkins_home
--
# jenkins_data= Volume at Docker host 
# /var/jenkins_home=Path at the container 
    volumes:
      - sonarqube_data:/opt/sonarqube/data
--
    volumes:
      - nexus_data:/nexus-data
# the new voumes will contain the project name "jenk-sona-nex"


ls -ltr /var/lib/docker/volumes
total 56
drwx-----x 3 root root  4096 Jul 29 06:41 jenk-sona-nex_nexus_data
drwx-----x 3 root root  4096 Jul 29 06:41 jenk-sona-nex_jenkins_data
drwx-----x 3 root root  4096 Jul 29 06:41 jenk-sona-nex_sonarqube_data
drwx-----x 3 root root  4096 Jul 29 06:41 jenk-sona-nex_sonarqube_extensions
```

إليك التوضيح المرتّب والمُجمل لكل جزء طلبته، بأسلوب واضح وسهل التدوين، مع اعتماد التعريفات من توثيق Docker الرسمي حيث لزم:

---

## 2. خاصية `environment:` في Docker Compose

تُمكّنك هذه الخاصية من تحديد **environment variables** داخل الحاوية، سواء بصيغة **قائمة** أو **خريطة**. يمكن استخدامها للتحكّم في إعدادات التطبيق أثناء وقت التشغيل.
* شرح لل env variables 
[شرح](../General%20Concepts/Env-Variables.md)
---

## 3. خاصية `ulimits:` في Docker Compose

تُستخدم لضبط حدود النظام (مثل عدد الملفات المفتوحة) داخل الحاوية. يمكن تحديد قيمة واحدة أو تحديد `soft` و`hard` لكل حد.([Docker Documentation][2])

* **Soft limit:** الحد القابل للزيادة داخل الحاوية.
* **Hard limit:** الحد الأقصى الذي لا يمكن تجاوزه دون صلاحيات خاصة (root أو CAP\_SYS\_RESOURCE).

مثال:

```yaml
ulimits:
  nofile:
    soft: 65536
    hard: 65536
```

هذا يرفع عدد الملفات المفتوحة (`nofile`) المسموح بها إلى حد أعلى داخل الحاوية مقارنة بالقيمة الافتراضية.([Stack Overflow][3], [Discuss the Elastic Stack][4])

---

## 4. خاصية `ports:` في Docker Compose

تُستخدم لربط المنافذ بين الـ **host** وداخل الـ **container**:

```yaml
ports:
  - "8080:8080"
  - "50000:50000"
```

* **التركيبة `host_port:container_port`**:
  * the first port from the lift is of docker host port 
  * the second one is for container port 
  * `8080:8080`: يسمح بالوصل إلى منفذ 8080 على المضيف ويُوجّه إلى نفس المنفذ داخل الحاوية (لوحة Jenkins).
  * `50000:50000`: منفذ Jenkins agent للتواصل.



<deb>