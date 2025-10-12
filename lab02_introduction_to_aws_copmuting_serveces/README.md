# Лабораторная работа №2. Введение в AWS. Вычислительные сервисы

## Описание лабораторной работы

### Постановка задачи

Лабораторная работа направлена на знакомство с основными вычислительными сервисами Amazon Web Services (AWS), включая создание и настройку виртуальных машин EC2, управление доступом через IAM, настройку мониторинга и развертывание веб-приложений.


### Цель

Освоить основы работы с облачной инфраструктурой AWS, научиться создавать и управлять виртуальными машинами, настраивать безопасность и мониторинг.

### Основные этапы:

0. Подготовка среды
1. Создание IAM пользователей и групп
2. Настройка бюджета для контроля расходов
3. Запуск и конфигурация EC2 инстансов
4. Настройка веб-сервера nginx
5. Мониторинг и логирование
6. Подключение по SSH
7. Развертывание Docker-приложения

## Практическая часть

### Условия

#### Задание 0. Подготовка среды

1. Зарегистрировался в AWS и создал бесплатный аккаунт (Free Tier).

    * Перешёл по ссылке: https://aws.amazon.com/
    * Нажал "Create an AWS Account" и проследовал инструкциям.

2. Вошёл в консоль управления под root-пользователем.
3. В правом верхнем углу выбрал регион EU (Frankfurt) `eu-central-1`.

<img width="974" height="470" alt="image" src="https://github.com/user-attachments/assets/6510ffbc-de17-48eb-b5e7-d97a231f57a4" />


#### Задание 1. Создание IAM группы и пользователя

IAM — это сервис для управления доступом в AWS. Здесь создаются пользователи, группы и политики (наборы прав).

1. Открыл сервис IAM (Identity and Access Management).
2. Создал IAM группу `Admins`:

    * Перешёл в раздел "`Groups`" и Нажал "`Create New Group`".
    * Ввёл имя группы `Admins` и Нажал "Next Step".
    * На шаге "`Attach Policy`" выбрал политику `AdministratorAccess`.

<img width="974" height="466" alt="image" src="https://github.com/user-attachments/assets/9c3a3610-de4a-43f5-9511-44c3380212a0" />

<img width="974" height="466" alt="image" src="https://github.com/user-attachments/assets/afc62a64-e188-42e3-b3b9-d676249ed7a2" />

<img width="974" height="463" alt="image" src="https://github.com/user-attachments/assets/07276829-501b-4559-99fa-12ffd21c2297" />


Что делает данная политика?

Политика `AdministratorAccess` предоставляет полный доступ ко всем сервисам и ресурсам AWS, позволяя управлять всеми аспектами облачной инфраструктуры.


3. Создал IAM пользователя с любым именем:
    
    * Перешёл в раздел "Users" и нажал "Add user".
    * Ввёл имя пользователя `admin`.
    * Привязал пользователя к группе `Admins`.
    * Разрешил пользователю доступ в AWS Management Console.
  
<img width="974" height="882" alt="image" src="https://github.com/user-attachments/assets/d6af2056-78bf-4f50-bc19-6c7474ba6751" />


4. Убедился, что пользователь создан и имеет доступ к консоли.

<img width="974" height="954" alt="image" src="https://github.com/user-attachments/assets/5bef2cc8-6e5a-41d8-8793-cc72fdde6c31" />


5. Вышел из консоли под root-пользователем и Вошёл под новым IAM пользователем.

<img width="974" height="472" alt="image" src="https://github.com/user-attachments/assets/9702dce0-c68c-40c6-ada0-453a21593b2f" />


#### Задание 2. Настройка Zero-Spend Budget

1. Открыл сервис Billing and Cost Management.
2. В меню слева выбрал Budgets → Create budget.
3. Выбрал "Zero spend budget" шаблон и указал следующие параметры:

    * Budget name: ZeroSpend
    * Email recipients: ваш email

<img width="974" height="426" alt="image" src="https://github.com/user-attachments/assets/dd8d7c9e-0b71-446f-a882-1f898cb5b54d" />


4. Нажал "Create budget" внизу страницы.

<img width="563" height="383" alt="image" src="https://github.com/user-attachments/assets/b0667a20-e5d8-4e77-9b1f-921961bae519" />


После создания данного бюджета буду получать уведомления, если расходы превысят $0.

#### Задание 3. Создание и запуск EC2 экземпляра (виртуальной машины)

Для запуска и настройки виртуальной машины используется сервис Amazon EC2 (Elastic Compute Cloud).

1. Открыл сервис EC2.
2. В меню слева выбрал Instances → Launch instances.
3. Заполнил соответствующие параметры для запуска виртуальной машины:

    1. Name and tags: `webserver`.
    
    2. AMI: выбрал `Amazon Linux 2023 AMI`. Это образ, который будет использоваться для создания виртуальной машины.
    
    3. Instance type: t3.micro.

<img width="376" height="454" alt="image" src="https://github.com/user-attachments/assets/ec345983-57d9-4914-932f-dea6c7a90a54" />

    
    4. Key pair. Это криптографическая пара ключей (приватный и публичный). Она нужна для безопасного входа на сервер по SSH.
       
        1. Выбрал "Create a new key pair".
    
        2. Ввёл имя для ключа в формате `yournickname-keypair`.
    
        3. Нажал "Create key pair" и скачал файл с приватным ключом (расширение .pem). Сохранил его в надежном месте.

    5. Security group. Это набор правил, которые определяют, какой трафик разрешен к экземпляру.

        1. Выбрал "Create a new security group".
    
        2. Ввёл имя группы `webserver-sg`.
    
        3. Добавил два правила для входящего трафика (Inbound rules).

        * Разрешить входящий HTTP трафик с любого IP-адреса.
    
        * Разрешить входящий SSH трафик только с текущего IP-адреса.

    6. Network settings. Оставил настройки по умолчанию. AWS автоматически создаст виртуальную сеть (VPC) и подсеть (subnet).

    7. Configure Storage. Оставил настройки по умолчанию.

<img width="559" height="453" alt="image" src="https://github.com/user-attachments/assets/97a66085-f45f-4570-ac7b-068a7fb678cb" />

<img width="565" height="456" alt="image" src="https://github.com/user-attachments/assets/704c219e-4267-4373-8ab2-3f425ff97cae" />

    8. Пролистал вниз до Advanced details → User Data и вставил следующий скрипт:

```bash
#!/bin/bash
dnf -y update
dnf -y install htop
dnf -y install nginx
systemctl enable nginx
systemctl start nginx
```

<img width="974" height="646" alt="image" src="https://github.com/user-attachments/assets/c023309a-e7bb-494e-90e1-3ba69745a1ea" />

<img width="758" height="98" alt="image" src="https://github.com/user-attachments/assets/6f3ec8f0-bf75-468b-9572-69bf4fa7f25d" />


В зависимости от выбранного AMI, команды в скрипте могут отличаться.

`Что такое User Data и какую роль выполняет данный скрипт? Для чего используется nginx?`

* User Data - это скрипт, который выполняется при первом запуске EC2 инстанса. Данный скрипт обновляет систему, устанавливает пакеты htop и nginx, а также запускает веб-сервер nginx.
* nginx - это высокопроизводительный веб-сервер, который используется для обслуживания веб-страниц и приложений, а также может работать как обратный прокси и балансировщик нагрузки.

4. Нажал Launch instance и дождался статуса Running и Status checks: 2/2. После того, как виртуальная машина запустится, увидел её публичный IP-адрес в колонке "IPv4 Public IP".

5. Проверил, что веб-сервер работает, открыв в браузере URL: http://<Public-IP>, где <Public-IP> — это публичный IP-адрес виртуальной машины.

   <img width="974" height="378" alt="image" src="https://github.com/user-attachments/assets/a7916486-b3c8-4095-88ee-bf6c9e0c2a2d" />

   <img width="974" height="454" alt="image" src="https://github.com/user-attachments/assets/d5e1aab7-a637-40cc-a914-21dab82c50de" />


#### Задание 4. Логирование и мониторинг

Мониторинг — это важная часть обеспечения надёжности, доступности и производительности экземпляров Amazon EC2 и решений в AWS.

1. Открыл вкладку Status checks.

* В карточке инстанса EC2 нашёл вкладку Status checks.

* Здесь могу быстро определить, выявил ли Amazon EC2 какие-либо проблемы, которые могут помешать работе приложений.

* Amazon EC2 выполняет автоматические проверки для каждого работающего экземпляра:

    * System reachability check — проверяет инфраструктуру AWS (железо и гипервизор).

    * Instance reachability check — проверяет, доступна ли операционная система на уровне инстанса.

* Убедился, что обе проверки прошли успешно (2/2 checks passed).

<img width="974" height="292" alt="image" src="https://github.com/user-attachments/assets/78cb6bc2-9084-434e-b4eb-007984462097" />


2. Открыл вкладку Monitoring.
* На этой вкладке отображаются метрики Amazon CloudWatch для инстанса.
* Так как инстанс был создан недавно, метрик пока немного. 
* Могу нажать на иконку с тремя точками на любом графике и выбрать Enlarge, чтобы открыть метрику в развёрнутом виде.
* По умолчанию включён базовый мониторинг (Basic monitoring) — данные отправляются в CloudWatch каждые 5 минут.
* При необходимости можно включить детализированный мониторинг (Detailed monitoring) — метрики будут отправляться каждую минуту.

`В каких случаях важно включать детализированный мониторинг?`

Детализированный мониторинг важен для критически важных приложений, когда необходимо быстро реагировать на изменения производительности, для диагностики проблем в реальном времени и для приложений с высокой нагрузкой, где каждая минута простоя критична.

<img width="974" height="598" alt="image" src="https://github.com/user-attachments/assets/f292f4e3-ba4c-4650-9afb-6d0b42825ec3" />

<img width="803" height="481" alt="image" src="https://github.com/user-attachments/assets/eef18b4b-ee22-45ed-80eb-551dd12ac402" />

<img width="974" height="444" alt="image" src="https://github.com/user-attachments/assets/5011502e-d3a3-4fca-8dfd-a746c2cf87dd" />


3. Просмотр системного лога (System Log)

* В верхнем меню нажал `Actions` → `Monitor and troubleshoot` → `Get system log`.
* Здесь отображается вывод консоли инстанса. Это полезный инструмент для диагностики:
    * помогает разбирать ошибки ядра,
    * ошибки конфигурации сервисов,
    * проблемы, из-за которых инстанс может завершиться или стать недоступным до старта SSH.

* Пролистал вывод и нашёл строки, показывающие установку пакетов (например, nginx из User Data).
* нажал Cancel, чтобы выйти.

<img width="974" height="873" alt="image" src="https://github.com/user-attachments/assets/6be5864f-2030-432f-b78a-ce7ec1e16620" />


4. Просмотр снимка экрана инстанса (Instance Screenshot)

    * В меню выбрал `Actions` → `Monitor and troubleshoot` → `Get instance screenshot`. увидел изображение консоли EC2 (как если бы к нему был подключён монитор).
    * Это особенно полезно, если не могу подключиться к инстансу по SSH: скриншот помогает понять, зависла ли ОС, есть ли kernel panic или другие ошибки.
    * нажал Cancel, чтобы выйти.
  
<img width="974" height="152" alt="image" src="https://github.com/user-attachments/assets/ab1ca597-128a-4549-880e-c74d1c608fb9" />


#### Задание 5. Подключение к EC2 инстансу по SSH

1. Открыл терминал на компьютере.
2. Перешёл в директорию, где сохранён файл приватного ключа .pem, для этого использовал команду

```bash
cd /path/to/my/key
```

3. Установил права на ключ (для Linux):

```bash
chmod 400 yournickname-keypair.pem
```

<img width="581" height="797" alt="image" src="https://github.com/user-attachments/assets/ad2f9a08-3f66-4992-a5e4-00edee390d4c" />


* Файл ключа .pem находится в директории, доступной только пользователю,и не имеет разрешений для других пользователей.

* Настрол следующим образом:

    * Щёлкнул правой кнопкой мыши на файле .pem и выбрал "Свойства".
    * Перешёл на вкладку "Безопасность".
    * Убедился, что доступ есть только у учётной записи Windows.
    Удалил права у «Все» (Everyone) или других пользователей.

<img width="974" height="712" alt="image" src="https://github.com/user-attachments/assets/988b4b93-3aaf-424c-942c-15dc93846d23" />


5. Подключился к инстансу по SSH:

```bash
ssh -i yournickname-keypair.pem ec2-user@<Public-IP>
```
где,

* -i — это параметр, указывающий на файл приватного ключа.
* menickname-keypair.pem — это имя файла с приватным ключом.
* ec2-user — это стандартное имя пользователя для Amazon Linux AMI.
* <Public-IP> — это публичный IP-адрес инстанса EC2.

После успешного подключения увидел приглашение командной строки: 

<img width="974" height="159" alt="image" src="https://github.com/user-attachments/assets/4f101d10-37c7-45f8-9d8d-ecdd6a04d09a" />

Выполнил команду для проверки статуса веб-сервера 
Nginx:
```bash
systemctl status nginx
```

`Почему в AWS нельзя использовать пароль для входа по SSH?`

В AWS используется аутентификация по ключам для повышения безопасности. Пары ключей обеспечивают более надежную защиту, чем пароли, так как исключают атаки брутфорс и перехват паролей. Приватный ключ хранится только у пользователя, что делает доступ более безопасным.

Далее, в зависимости от специализации, выбрал одно из трёх заданий (6c). Для специализации DevOps — рекомендуется задание 6c.


#### Задание 6c. Запуск PHP-приложения в Docker (Для специализации DevOps)

Docker позволяет запускать приложения в контейнерах — изолированных средах, которые включают всё необходимое для работы приложения (библиотеки, зависимости, сервер). В AWS могу использовать Docker на EC2, а также готовые образы из Docker Hub или AWS Marketplace.

1. Подключился к инстансу EC2 по SSH
2. Установил Docker

```bash
sudo dnf -y install docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
```

Проверил, что Docker работает:

```bash
docker --version
```

<img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/989f282c-1762-4e19-9f55-12a7da9e8aaa" />

3. Вышел из сессии SSH и Подключился снова, чтобы обновить группы пользователя.

```bash
exit
```

4. Используя docker compose, развернул PHP-приложение (созданное в рамках лабораторной работы по основам веб-разработки). Для работы приложения необходимо поднять несколько контейнеров, каждый из которых отвечает за свою часть инфраструктуры:

* nginx — веб-сервер, принимающий HTTP-запросы и перенаправляющий их в PHP-обработчик.
* php-fpm — сервис для интерпретации и выполнения PHP-кода.
* mysql — реляционная база данных для хранения информации приложения.
* adminer — лёгкий веб-интерфейс для администрирования базы данных (альтернатива phpMyAdmin).

  <img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/22a5bc29-b57d-4ffd-bd9f-9c634de1e6f0" />


5. После запуска Убедился, что:
* Приложение доступно по адресу http://<Public-IP>.
* Приложение корректно взаимодействует с базой данных MySQL.
* Админка Adminer доступна по адресу http://<Public-IP>:8080.

  <img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/63d26ba3-6af8-4c43-a550-ecea2e7a706c" />

<img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/503ae81d-ee16-4013-9b71-9f50ba09697d" />

<img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/6e521082-cc82-4304-8044-051e54d54dfa" />

<img width="974" height="528" alt="image" src="https://github.com/user-attachments/assets/4b50f7c8-8a4f-4005-a040-6bce16775037" />


#### Задание 7. Завершение работы и удаление ресурсов
1. Остановил запущенную виртуальную машину (инстанс EC2) используя AWS CLI.
2. Удалять виртуальную машину не обязательно, так как в следующей лабораторной работе буду работать с тем же инстансом.

`Чем «Stop» отличается от «Terminate»`

* Stop: Временная остановка инстанса. Сохраняются все данные на корневом EBS томе, инстанс можно запустить снова с теми же данными.

* Terminate: Полное удаление инстанса. По умолчанию удаляется корневой EBS том, инстанс нельзя восстановить.


## Список использованных источников

Официальная документация AWS: https://docs.aws.amazon.com/

AWS Free Tier: https://aws.amazon.com/free/

Amazon EC2 User Guide

IAM Documentation

Docker Documentation

nginx Documentation

Курс Cloud Computing moodle: https://elearning.usm.md/course/view.php?id=7420

## Дополнительные аспекты
Все ресурсы созданы в регионе eu-central-1 для соответствия требованиям

Использованы только сервисы, входящие в Free Tier

Настроен бюджет для контроля расходов

Применены лучшие практики безопасности (IAM пользователи, security groups)

Реализована отказоустойчивая архитектура с использованием Docker
