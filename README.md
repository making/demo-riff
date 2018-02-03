
### Docker for Mac (Edge)

```
brew cask install docker-edge
```

メモリを4GBにして、Kubernetesタブで`Enable Kubernetes`にチェック。

![image](https://user-images.githubusercontent.com/106908/35770205-47f5c618-095a-11e8-8653-f7e3be3ca302.png)

![image](https://user-images.githubusercontent.com/106908/35770209-56689ac2-095a-11e8-8b41-2bc407d01355.png)

```
kubectl config uset-context docker-for-desktop
```

### Hemlのセットアップ

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


```
curl -Lo riff https://github.com/projectriff/riff/releases/download/v0.0.3/riff && chmod +x riff && sudo mv riff /usr/local/bin/
```

### Sample Functions

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

`Promise`も使える

``` js
cat <<EOF > square.js
module.exports = (x) => Promise.resolve(x ** 2);
EOF
```

async/await

``` js
cat <<EOF > square.js
module.exports = async (x) => x ** 2;
EOF
```


```
riff init -i numbers -u making
riff build -u making
riff apply
```

ショートカット版

```
riff create -i numbers -u making
```


`riff build`も`riff create`も`--push`をつけるとDocker Registryにpushできる。

同期

```
riff publish -i numbers -d 10
```

非同期

```
riff publish -i numbers -d 10 -r
```

### Shell Scriptの場合


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

### Pythonの場合


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

    while True:
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

### Javaの場合

```
cd ../..
mkdir -p java/hello
cd java/hello
```

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
riff publish -i names -d world
```

### Java (Window処理)の場合

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


```
riff create --input words -u making --artifact func.jar --handler functions.WordCounter
```


```
riff publish -i words -d "Hello World"
```
