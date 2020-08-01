目前为止学到的知识：

1. 简单的 python 命令，安装 python，建立 venv，并在 venv 内安装 extension。

2. python web development 的基本文件结构，运行 flask run 时执行文件的先后顺序。（重点）

3. 什么是 view function？ 什么是 url_for ？ 有什么不一样？（重点）

4. 怎样结合 python 和 html 写 template ？ 怎样写 view function， 怎样在 view function 中传递参数到指定的 template ？（重点）

5. template 之间是怎样继承和嫁接的？

6. 怎样定义 form class ？怎样定义 form template ？ 怎样用 view function 把 form class 和 form template 结合起来，然后把输入的资料储存在对应的 model 中？ 怎样写 redirect 动作？（重点）

7. 更新 database 结构时使用什么命令？如何在应用中设置添加 SQLite ？ `app.db` 是什么文件？

8. 处理用户登陆等一系列动作时用到哪些 extension ？flask_login 中有哪些重要的函数，有哪几个是自动调用函数？wtforms 中哪一个是自动调用函数？（难点）

9. 如何连接到动态 URL ？ 比如说特定的 username 的 profile 有特定的 URL ？这个情况下的 view function 是怎样写？ template 怎样写？（难点）

10. 如何生成基于原型编辑的 form ？

11. 如何设置 environment 变量？ 如何设置 global 变量？ 有什么不同？

12. 什么是 debug 模式？ 怎样开启？

13. 关闭 debug 模式后，有哪两种方式收集错误信息？ 如何设置？

14. 如何定制错误显示页？

15. 如何引入 bootstrap ？ 如何运用到相关 template 之中？