### Docker for Mac Edgeの用意

ローカルk8sとしてDocker for Mac (Edge)を使います。

```
brew cask install docker-edge
```

メモリを4GBにして、Kubernetesタブで`Enable Kubernetes`にチェック。

<img src="https://user-images.githubusercontent.com/106908/35770205-47f5c618-095a-11e8-8653-f7e3be3ca302.png" width="480px" />

<img src="https://user-images.githubusercontent.com/106908/35770209-56689ac2-095a-11e8-8b41-2bc407d01355.png" width="480px" />

```
kubectl config uset-context docker-for-desktop
```

### Hemlのセットアップ

RiffはHelmでインストールできます。

```
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account=tiller

helm repo add riffrepo https://riff-charts.storage.googleapis.com
helm repo update
```


### Riffのインストール

```
helm install riffrepo/riff --name demo \
     --version 0.0.3-rbac \
     --set httpGateway.service.type=NodePort
```


```
$ kubectl get all
NAME                                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/demo-riff-function-controller   1         1         1            1           44s
deploy/demo-riff-http-gateway          1         1         1            1           44s
deploy/demo-riff-kafka                 1         1         1            1           44s
deploy/demo-riff-topic-controller      1         1         1            1           44s
deploy/demo-riff-zookeeper             1         1         1            1           44s

NAME                                          DESIRED   CURRENT   READY     AGE
rs/demo-riff-function-controller-5df6c848d5   1         1         1         44s
rs/demo-riff-http-gateway-7cc944f97c          1         1         1         44s
rs/demo-riff-kafka-65555dbb87                 1         1         1         44s
rs/demo-riff-topic-controller-67ccb96678      1         1         1         44s
rs/demo-riff-zookeeper-859688cdc8             1         1         1         44s

NAME                                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/demo-riff-function-controller   1         1         1            1           44s
deploy/demo-riff-http-gateway          1         1         1            1           44s
deploy/demo-riff-kafka                 1         1         1            1           44s
deploy/demo-riff-topic-controller      1         1         1            1           44s
deploy/demo-riff-zookeeper             1         1         1            1           44s

NAME                                          DESIRED   CURRENT   READY     AGE
rs/demo-riff-function-controller-5df6c848d5   1         1         1         44s
rs/demo-riff-http-gateway-7cc944f97c          1         1         1         44s
rs/demo-riff-kafka-65555dbb87                 1         1         1         44s
rs/demo-riff-topic-controller-67ccb96678      1         1         1         44s
rs/demo-riff-zookeeper-859688cdc8             1         1         1         44s

NAME                                                READY     STATUS    RESTARTS   AGE
po/demo-riff-function-controller-5df6c848d5-xtj2w   1/1       Running   0          44s
po/demo-riff-http-gateway-7cc944f97c-8c9kx          1/1       Running   1          44s
po/demo-riff-kafka-65555dbb87-w7q95                 1/1       Running   0          44s
po/demo-riff-topic-controller-67ccb96678-9rkkb      1/1       Running   0          44s
po/demo-riff-zookeeper-859688cdc8-pxt5h             1/1       Running   0          44s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
svc/demo-riff-http-gateway   NodePort    10.97.115.228   <none>        80:32356/TCP   44s
svc/demo-riff-kafka          ClusterIP   10.110.227.80   <none>        9092/TCP       44s
svc/demo-riff-zookeeper      ClusterIP   10.101.79.249   <none>        2181/TCP       44s
svc/kubernetes               ClusterIP   10.96.0.1       <none>        443/TCP        17m
```

### Riff CLIのインストール

ヘルパースクリプトとして`riff` CLIが用意されています。

```
curl -Lo riff https://github.com/projectriff/riff/releases/download/v0.0.3/riff && chmod +x riff && sudo mv riff /usr/local/bin/
```

今はshell scriptですが、goで書き直し中です。

### Sample Functions

現時点でFunction Invokerは

* JavaScript
* ShellScript
* Python2
* Java

が公式に利用可能です。

次のディレクトリで作業します。

```
mkdir samples
cd samples
```

#### JavaScriptの場合

```
mkdir -p node/square
cd node/square
```

``` js
cat <<EOF > square.js
module.exports = (x) => x ** 2;
EOF
```

`Promise`も使えます。

``` js
cat <<EOF > square.js
module.exports = (x) => Promise.resolve(x ** 2);
EOF
```

async/awaitも使えます。

``` js
cat <<EOF > square.js
module.exports = async (x) => x ** 2;
EOF
```


```
riff init -i numbers -u making
```

次のファイルができます。

```
$ ls -l
total 32
-rw-r--r--  1 maki  staff  113  2  3 22:31 Dockerfile
-rw-r--r--  1 maki  staff  154  2  3 22:31 square-function.yaml
-rw-r--r--  1 maki  staff   90  2  3 22:31 square-topics.yaml
-rw-r--r--  1 maki  staff   38  2  4 03:26 square.js
```

`Dockerfile`

```
FROM projectriff/node-function-invoker:0.0.3
ENV FUNCTION_URI /functions/square.js
ADD square.js ${FUNCTION_URI}
```

`square-function.yaml`

``` yaml
apiVersion: projectriff.io/v1
kind: Function
metadata:
  name: square
spec:
  protocol: http
  input: numbers
  container:
    image: making/square:0.0.1
```

`square-topics.yaml`


```
apiVersion: projectriff.io/v1
kind: Topic
metadata:
  name: numbers
spec:
  partitions: 1
```

`docker`コマンドと`kubectl`コマンドでビルドとデプロイをしても良いですが、
`riff`コマンドでラップされています。こちらの方が楽です。

```
riff build -u making
riff apply
```


以上の`riff`コマンドのショートカット版が

```
riff create -i numbers -u making
```

です。

`riff build`も`riff create`も`--push`をつけるとDocker Registryにpushできます。

同期リクエストを送る場合は

```
$ riff publish -i numbers -d 10 -r
100
```

非同期リクエストを送る場合は

```
$ riff publish -i numbers -d 10 
message published to topic: numbers
```

#### Shell Scriptの場合


```
mkdir -p shell/upper
cd shell/upper
```

``` sh
cat <<'EOF' > upper.sh
#!/bin/bash
echo $1 | tr [:lower:] [:upper:]
EOF
chmod +x upper.sh
```

```
riff create -i lower -u making
```

```
riff publish -i lower -d hello -r
```

#### Pythonの場合


```
mkdir -p pyhon/lower
cd pyhon/lower
```

``` python
cat <<'EOF' > lower.py
# -*- coding: utf-8 -*-
def process(data):
    print(data.lower())

if __name__ == '__main__':
    data = raw_input()
    process(data)
EOF
cat <<'EOF' > requirements.txt
EOF
```

```
riff create -i upper -u making --handler process
```

```
riff publish -i upper -d HELLO -r
```

#### Javaの場合

```
cd ../..
mkdir -p java/hello
cd java/hello
```

Mavenプロジェクトでもいいのですが、`javac`と`jar`コマンドだけで関数jarファイルを実装します。

``` java
mkdir -p src/functions
cat <<EOF > src/functions/Hello.java
package functions;

import java.util.function.Function;

public class Hello implements Function<String, String> {
    public String apply(String name) {
        return "Hello " + name;
    }
}
EOF
```

```
mkdir classes
javac -sourcepath src -d classes src/functions/Hello.java
jar -cvf func.jar -C classes .
```

```
riff create --input names -u making --artifact func.jar --handler functions.Hello
```


```
riff publish -i names -d world -r
```

この関数はSpring Cloud Function上のIsolated Classloader上で実行されます。

#### JavaでWindow処理の場合

[Reactor](https://projectreactor.io/)を使ってWindow処理ができます。

```
cd ../..
mkdir -p java/wordcounter
cd java/wordcounter
```


``` java
mkdir -p src/functions
cat <<'EOF' > src/functions/WordCounter.java
package functions;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

import reactor.core.publisher.Flux;

public class WordCounter implements Function<Flux<String>, Flux<Map<String, Integer>>> {

    @Override
    public Flux<Map<String, Integer>> apply(Flux<String> words) {
        return words.window(Duration.ofSeconds(3))
                .flatMap(f -> f.flatMap(word -> Flux.fromArray(word.split("\\W")))
                        .reduce(new HashMap<String, Integer>(), (map, word) -> {
                            map.merge(word, 1, Integer::sum);
                            return map;
                        }));
    }
}
EOF
```

```
mkdir classes
mkdir libs
cd libs
curl -L -O -J http://central.maven.org/maven2/org/reactivestreams/reactive-streams/1.0.2/reactive-streams-1.0.2.jar
curl -L -O -J https://repo.spring.io/milestone/io/projectreactor/reactor-core/3.2.0.M1/reactor-core-3.2.0.M1.jar
cd ..
javac -cp .:libs/* -sourcepath src -d classes src/functions/WordCounter.java -cp libs/*
jar -cvf func.jar -C classes .
```

ReactorとReactive Streamsはjava-function-invokerに含まれるのでjarに同梱する必要がありません。

```
riff create --input words -u making --artifact func.jar --handler functions.WordCounter
```


```
riff publish -i words -d "Hello World" -r
```

3秒間で受信したメッセージのWord Countを集計します。

#### Javaで既存のfunction jarを使用

```
cd ../..
mkdir -p java/fizzbuzz
cd java/fizzbuzz
```

```
cat <<'EOF' > Dockerfile
FROM projectriff/java-function-invoker:0.0.3
ENV FUNCTION_URI http://central.maven.org/maven2/am/ik/functions/fizz-buzz/1.0.0/fizz-buzz-1.0.0.jar?handler=am.ik.functions.FizzBuzz
EOF
```

```
docker build -t making/fizzbuzz:0.0.1 .
```

``` yaml
cat <<'EOF' > fizzbuzz.yaml
apiVersion: projectriff.io/v1
kind: Topic
metadata:
  name: fizzbuzz
spec:
  partitions: 1
---
apiVersion: projectriff.io/v1
kind: Function
metadata:
  name: fizzbuzz
spec:
  protocol: pipes
  input: fizzbuzz
  container:
    image: making/fizzbuzz:0.0.1
EOF
```

```
kubectl apply -f .
```