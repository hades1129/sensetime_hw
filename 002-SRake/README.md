#SRake - Simple Rake

样例文件：```test.rake```


````
task :default => :test3

desc 'task1'
task :test1 do
  sh 'echo task1'
end

desc 'task2'
task :test2 => :test1 do
  sh 'echo task2'
end

desc 'task3'
task :test3 => [:test1, :test2] do
  sh 'echo task3'
end

task :test4 => :test5 do
  sh 'echo task4'
end
````


```$ ruby ./simplerake.rb -T  test2.rake``` 
参考输出：
```
test1        #task1
test2        #task2
test3        #task3
test4        #

```


```$ ruby ./simplerake.rb -T  test2.rake``` 
参考输出：
```
task1
task2
task3

```


```$ ruby ./simplerake.rb  test2.rake test4```
参考输出：
```F, [2015-09-08T17:50:11.634694 #53015] FATAL -- : The prerequisite doesn't exist for task.```



编译环境：Ruby 1.9

