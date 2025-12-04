# Лабораторная работа №6. Балансирование нагрузки в облаке и авто-масштабирование

**Выполнил:** Zabudico Alexandr
**Группа:** I-2302 ru ș.e.  
**Дата выполнения:** 02.12.2024  
**Специализация:** DevOps

## 1. Описание лабораторной работы

### 1.1. Постановка задачи

Целью лабораторной работы является создание отказоустойчивой и автоматически масштабируемой архитектуры в AWS с использованием:
- Amazon VPC с публичными и приватными подсетями
- Виртуальных машин EC2 с веб-сервером nginx
- Application Load Balancer (ALB) для распределения нагрузки
- Auto Scaling Group для автоматического масштабирования
- CloudWatch для мониторинга и автоматического реагирования на нагрузку

### 1.2. Цель и основные этапы работы

**Цель:** Закрепить навыки работы с AWS EC2, Elastic Load Balancer, Auto Scaling и CloudWatch, создав отказоустойчивую и автоматически масштабируемую архитектуру.

**Основные этапы:**
1. Создание VPC с публичными и приватными подсетями
2. Развертывание виртуальной машины с веб-сервером nginx
3. Создание AMI (Amazon Machine Image)
4. Создание Launch Template
5. Создание Target Group
6. Настройка Application Load Balancer
7. Создание и настройка Auto Scaling Group
8. Тестирование балансировки нагрузки
9. Тестирование авто-масштабирования
10. Очистка ресурсов

## 2. Практическая часть

### 2.1. Подготовка и настройка Terraform

Для автоматизации развертывания инфраструктуры использовался Terraform. Была создана конфигурация, включающая все необходимые ресурсы AWS.

**Используемые инструменты:**
- Terraform v1.0+
- AWS CLI
- PowerShell для выполнения скриптов

**Структура проекта:**
```
lab06_Cloud_Load_Balancer_And_AutoScaling/
├── terraform/
│   ├── main.tf          # Основная конфигурация
│   └── terraform.tfvars # Переменные
└── scripts/
    └── load_test.ps1    # Скрипт нагрузочного тестирования
```

### 2.2. Создание VPC и подсетей

**Выполнено:**
- Создана VPC с CIDR блоком `10.0.0.0/16`
- Созданы 2 публичные подсети в разных зонах доступности:
  - `10.0.1.0/24` (us-east-1a)
  - `10.0.2.0/24` (us-east-1b)
- Созданы 2 приватные подсети:
  - `10.0.3.0/24` (us-east-1a)
  - `10.0.4.0/24` (us-east-1b)
- Создан и прикреплен Internet Gateway
- Настроены таблицы маршрутизации:
  - Для публичных подсетей: маршрут `0.0.0.0/0` → Internet Gateway
  - Для приватных подсетей: маршрут `0.0.0.0/0` → NAT Gateway
- Создан NAT Gateway для обеспечения доступа к интернету из приватных подсетей

**Скриншот 1: VPC с подсетями, Internet Gateway и NAT Gateway**

<img width="1581" height="334" alt="image" src="https://github.com/user-attachments/assets/504143aa-5720-4286-8ff9-82e27bc78692" />


**Код Terraform для VPC:**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # ... остальные параметры
}

resource "aws_subnet" "public_1" {
  cidr_block = "10.0.1.0/24"
  # ... остальные параметры
}
```

### 2.3. Создание виртуальной машины для AMI

**Выполнено:**
- Запущена виртуальная машина в публичной подсети
- Использован AMI: Amazon Linux 2
- Тип инстанса: t3.micro
- Настроена Security Group с правилами:
  - SSH (порт 22) - только с моего IP
  - HTTP (порт 80) - отовсюду
- Включен мониторинг CloudWatch
- Использован UserData для автоматической установки nginx

**UserData для установки nginx:**
```bash
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
# ... создание тестовых страниц
```

**Скриншот 2: EC2 Instance для создания AMI**

<img width="1573" height="458" alt="image" src="https://github.com/user-attachments/assets/9c12d4cd-3b13-44c3-8331-3b040843b683" />

### 2.4. Создание AMI

**Выполнено:**
- На основе запущенной виртуальной машины создан AMI
- AMI назван: `lab6-project-web-ami`
- AMI содержит предустановленный nginx и тестовые страницы

**Код Terraform:**
```hcl
resource "aws_ami_from_instance" "web_ami" {
  name               = "lab6-project-web-ami"
  source_instance_id = aws_instance.web_for_ami.id
}
```

**Скриншот 3: Созданный AMI в разделе AMIs**
<img width="1576" height="193" alt="image" src="https://github.com/user-attachments/assets/8801e10e-2c53-4228-9865-043fe4117e00" />

### 2.5. Создание Launch Template

**Выполнено:**
- Создан Launch Template на основе созданного AMI
- Название: `lab6-project-launch-template`
- Указан тип инстанса: t3.micro
- Использована та же Security Group
- Включен детальный мониторинг CloudWatch

**Скриншот 4: Launch Template в AWS Console**

<img width="1574" height="158" alt="image" src="https://github.com/user-attachments/assets/fbe47b2a-fa86-4a60-9807-6e42149befbf" />

### 2.6. Создание Target Group

**Выполнено:**
- Создана Target Group с названием `lab6-project-tg`
- Тип: Instances
- Протокол: HTTP, порт 80
- Настроены health checks на путь `/health`
- Timeout: 5 секунд, Interval: 30 секунд

**Скриншот 5: Target Group с настройками health check**

<img width="1556" height="828" alt="image" src="https://github.com/user-attachments/assets/094a5703-ca5e-4e81-8cd2-4479188c7b90" />


### 2.7. Создание Application Load Balancer

**Выполнено:**
- Создан Application Load Balancer типа Internet-facing
- Название: `lab6-project-alb`
- Привязан к публичным подсетям
- Настроен Listener на порту 80
- Default action: forward к Target Group

**DNS имя ALB:** `lab6-project-alb-xxxxxxxx.us-east-1.elb.amazonaws.com`

### 2.8. Создание Auto Scaling Group

**Выполнено:**
- Создана Auto Scaling Group: `lab6-project-asg-xxxxxxxx`
- Использован созданный Launch Template
- Минимальное количество инстансов: 2
- Максимальное количество: 4
- Желаемое количество: 2
- Инстансы запущены в приватных подсетях
- Настроена политика масштабирования по CPU (50%)
- Instance warm-up period: 300 секунд
- Привязана к Target Group

**Скриншот 7: Auto Scaling Group с инстансами**

<img width="1512" height="827" alt="image" src="https://github.com/user-attachments/assets/df3bf836-a519-4b20-a782-7b310c036e6e" />

### 2.9. Тестирование Application Load Balancer

**Выполнено:**
1. **Проверка доступности ALB:**
   ```powershell
   curl http://lab6-project-alb-727247504.us-east-1.elb.amazonaws.com
   ```
   Результат: Успешное подключение, отображение тестовой страницы

2. **Проверка балансировки нагрузки:**
   ```powershell
   for ($i=1; $i -le 10; $i++) { 
       curl -s http://lab6-project-alb-727247504.us-east-1.elb.amazonaws.com | Select-String "Instance ID:"
   }
   ```
   Результат: Запросы распределяются между разными инстансами

### 2.10. Тестирование Auto Scaling

**Выполнено:**
1. **Нагрузочное тестирование:**
   - Открыто 6 вкладок браузера с URL: `http://ALB-DNS/load.html`
   - Длительность теста: 120 секунд

2. **Мониторинг в CloudWatch:**
   - Наблюдался рост CPU Utilization
   - CloudWatch Alarm перешел в состояние ALARM
   - Auto Scaling Group увеличила количество инстансов

3. **Проверка результатов:**
   - Количество инстансов увеличилось с 2 до 4
   - После снижения нагрузки инстансы автоматически уменьшились

## 3. Контрольные вопросы и ответы

### 3.1. Что такое image и чем он отличается от snapshot?
**Ответ:** 
- **AMI (Amazon Machine Image)** - это полный образ виртуальной машины, содержащий операционную систему, приложения, конфигурации и данные.
- **Snapshot** - это копия EBS тома в определенный момент времени.
- **Отличие:** AMI может содержать несколько snapshots (для root volume и дополнительных томов), в то время как snapshot - это только копия одного тома.

### 3.2. Что такое Launch Template и зачем он нужен?
**Ответ:** Launch Template - это шаблон для запуска EC2 инстансов, содержащий все необходимые параметры: AMI, тип инстанса, security groups, ключи SSH, user data и другие настройки. Он обеспечивает версионность и воспроизводимость конфигураций, что особенно важно для Auto Scaling Groups.

### 3.3. Зачем необходим и какую роль выполняет Target Group?
**Ответ:** Target Group определяет цели для Application Load Balancer, обеспечивает health checks и распределение трафика между инстансами. Она отслеживает состояние инстансов и направляет трафик только к здоровым экземплярам.

### 3.4. В чем разница между Internet-facing и Internal?
**Ответ:**
- **Internet-facing** - доступен из интернета, имеет публичный DNS-адрес.
- **Internal** - доступен только внутри VPC, не имеет публичного доступа.

### 3.5. Что такое Default action и какие есть типы Default action?
**Ответ:** Default action - это действие, выполняемое Load Balancer'ом при отсутствии matching rules. Типы действий:
- **Forward** - перенаправление трафика в Target Group
- **Redirect** - перенаправление на другой URL
- **Fixed-response** - возврат фиксированного HTTP ответа

### 3.6. Почему для Auto Scaling Group выбираются приватные подсети?
**Ответ:** Приватные подсеты используются для безопасности - инстансы не имеют публичных IP-адресов, что уменьшает поверхность атаки. Весь входящий трафик идет через Application Load Balancer, а исходящий - через NAT Gateway.

### 3.7. Зачем нужна настройка: Availability Zone distribution?
**Ответ:** Распределение по зонам доступности обеспечивает отказоустойчивость. При выходе из строя одной зоны доступности, инстансы в других зонах продолжат работать, обеспечивая высокую доступность приложения.

### 3.8. Что такое Instance warm-up period и зачем он нужен?
**Ответ:** Instance warm-up period - это время, необходимое инстансу для инициализации перед тем, как он начнет учитываться в метриках Auto Scaling. В данной лабораторной работе установлен период 300 секунд для полной установки и настройки nginx.

### 3.9. Какие IP-адреса видно при обновлении страницы и почему?
**Ответ:** При обновлении страницы видны приватные IP-адреса разных инстансов из приватных подсетей. Это происходит потому, что Application Load Balancer балансирует трафик между всеми здоровыми инстансами в Target Group, показывая работу механизма балансировки нагрузки.

### 3.10. Какую роль сыграл Auto Scaling?
**Ответ:** Auto Scaling автоматически увеличил количество инстансов при высокой нагрузке на CPU (более 50%) и уменьшил при снижении нагрузки. Это обеспечило:
- Обработку повышенной нагрузки без снижения производительности
- Экономию ресурсов при низкой нагрузке
- Отказоустойчивость при выходе из строя отдельных инстансов

## 4. Вывод

В ходе лабораторной работы успешно создана и протестирована отказоустойчивая и автоматически масштабируемая архитектура в AWS. Были выполнены все поставленные задачи:

1. **Автоматизировано развертывание** инфраструктуры с помощью Terraform, что соответствует требованиям специализации DevOps.
2. **Создана сложная сетевая инфраструктура** с VPC, публичными и приватными подсетями, NAT Gateway.
3. **Реализована схема балансировки нагрузки** через Application Load Balancer.
4. **Настроено автоматическое масштабирование** на основе метрик CloudWatch.
5. **Протестирована работа** всех компонентов системы:
   - Балансировка нагрузки между инстансами
   - Автоматическое масштабирование при нагрузке
   - Самовосстановление при выходе инстансов из строя
6. **Получены практические навыки** работы с ключевыми сервисами AWS для построения масштабируемых и отказоустойчивых приложений.

**Основные достижения:**
- Успешная автоматизация всех этапов развертывания
- Демонстрация работы авто-масштабирования под нагрузкой
- Понимание взаимодействия различных сервисов AWS
- Применение best practices для обеспечения безопасности и отказоустойчивости

Работа подтвердила важность использования инфраструктуры как кода (IaC) для управления облачными ресурсами и продемонстрировала преимущества автоматического масштабирования для поддержания производительности приложения при изменении нагрузки.

## 5. Список использованных источников

1. Официальная документация AWS:
   - Amazon VPC: https://docs.aws.amazon.com/vpc/
   - Amazon EC2: https://docs.aws.amazon.com/ec2/
   - Elastic Load Balancing: https://docs.aws.amazon.com/elasticloadbalancing/
   - Auto Scaling: https://docs.aws.amazon.com/autoscaling/
   - CloudWatch: https://docs.aws.amazon.com/cloudwatch/

2. Документация Terraform:
   - AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

3. Учебные материалы курса "Облачные вычисления"

4. Спецификация лабораторной работы №6

---

**Приложение: Команды для воспроизведения**

```powershell
# Инициализация Terraform
terraform init

# План развертывания
terraform plan

# Развертывание инфраструктуры
terraform apply -auto-approve

# Тестирование
$ALB_DNS = terraform output -raw alb_dns_name
curl http://$ALB_DNS

# Нагрузочное тестирование
cd scripts
.\load_test.ps1 -AlbDnsName $ALB_DNS -Threads 6 -Duration 120

# Очистка ресурсов
terraform destroy -auto-approve
```



<img width="1717" height="684" alt="image" src="https://github.com/user-attachments/assets/bb057751-7a1a-4f30-ad02-6dc40e8d827a" />

<img width="1143" height="931" alt="image" src="https://github.com/user-attachments/assets/327e64c3-4c36-440a-a91e-4c76ca8083ae" />

<img width="1544" height="628" alt="image" src="https://github.com/user-attachments/assets/a620f4c3-0643-4a89-a4b9-cca21e2ee2f3" />

<img width="1661" height="478" alt="image" src="https://github.com/user-attachments/assets/06097076-1b41-4cd5-a1d9-76f24224e388" />

<img width="878" height="877" alt="image" src="https://github.com/user-attachments/assets/a5d9a469-957f-4d8f-9c15-410e6c3fab49" />

<img width="1116" height="845" alt="image" src="https://github.com/user-attachments/assets/effc5d51-8aa1-4f05-9fa0-59eb5c26b254" />

<img width="1739" height="333" alt="image" src="https://github.com/user-attachments/assets/fa141f38-cf23-4beb-9d3b-d496912c51fd" />

<img width="1715" height="322" alt="image" src="https://github.com/user-attachments/assets/3c5f6a17-2d71-4d30-a9ab-c6347d6e9d67" />
