# CitySpade

## 1. Environment
1. Above Mysql 5.5 
2. Above rails 4.1.4, ruby 2.1.1
3. Above redis 2.6

### 1.1 development
branch development

### 1.2 test 
Environment name:staging  
branch test  
bundle install rspec

### 1.3 production

## 2. Tech Stack

### 2.1 Front End：
1. slim, sass, coffee script
2. booststrap 2.3.2


### 2.1 Back End：
1. MySql

## 3. Git Commands

### 3.1 check and push
```
1. git status
2. git diff
3. git add -A
4. git commit -m"[your name]-feature"
5. git push origin <your branch name>
6. git push -f origin <your branch name>:develop
```

### 3.2 run in server
```
1. ssh ec2-user@test.cityspade.com
2. cd CitySpade
3. cap staging deploy  // subbranch -> Test
4. exec ssh-agent bash
5. ssh-add
6. cap production deploy
```
