import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meimei/bean/trend.dart';
import 'package:meimei/http/http_api.dart';
import 'package:meimei/utils/route_util.dart';
import 'package:meimei/utils/screen_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TrendPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TrendState();
}

class TrendState extends State<TrendPage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true; //加载中...
  RefreshController _mRefreshController;
  ScrollController controller = ScrollController();
  bool isShowFloatButton = false;
  int _currPage = 1;

  ///条目
  List<TrendBean> _trendList = [];

  @override
  void initState() {
    super.initState();

    ///默认不显示回首页按钮
    _mRefreshController = RefreshController();
    controller.addListener(() {
      var offset = controller.offset;
      var wHeight = YScreenUtil.getWinHeight();
//      print('滑动位置 $offset ');
//      \n 屏幕高度 $wHeight');
      ///查看log,发现这个位置相对比较合适
      if (offset < wHeight / 3 && isShowFloatButton) {
        setState(() {
          isShowFloatButton = false;
        });
      } else if (offset > wHeight / 3 && !isShowFloatButton) {
        setState(() {
          isShowFloatButton = true;
        });
      }
    });

    initData();
  }

  void initData() async {
    var data = await HttpApi.trendList();
    List<TrendBean> wanList = formatData(data);

    /// mounted 为 true 表示当前页面挂在到构件树中，为 false 时未挂载当前页面
    if (!mounted) {
      return;
    }
    if (_isLoading) {
      setState(() {
        _isLoading = false;
        _trendList.addAll(wanList);
      });
    }
  }

  ///下拉刷新
  void toRefresh() async {
    _currPage = 1;
    var data = await HttpApi.trendList(currPage: _currPage);
    List<TrendBean> wanList = formatData(data);

    await Future.delayed(Duration(milliseconds: 1000));
    _mRefreshController.refreshCompleted();
    setState(() {
      _trendList = wanList;
    });
  }

  ///上拉加载更多
  void getMore() async {
    _currPage++;
    var data = await HttpApi.trendList(currPage: _currPage);
    List<TrendBean> wanList = formatData(data);
    await Future.delayed(Duration(milliseconds: 1000));
    _mRefreshController.loadComplete();
    setState(() {
      _trendList.addAll(wanList);
    });
  }

  List<TrendBean> formatData(var data) {
    return data['d']['entrylist']
        .map<TrendBean>((bean) => TrendBean.fromJson(bean))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Offstage(
          offstage: _isLoading,
          child: SmartRefresher(
            header: Platform.isAndroid
                ? MaterialClassicHeader(
                    ///下拉状态的颜色
                    color: Theme.of(context).primaryColor,
                  )
                : ClassicHeader(),
            onRefresh: toRefresh,
            onLoading: getMore,
            controller: _mRefreshController,
            enablePullUp: true,
            child: listviewBuild(),
          ),
        ),
        yFloatingActionButton(),
        Offstage(
          offstage: !_isLoading,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        )
      ],
    );
  }

  ///回到顶部按钮
  Widget yFloatingActionButton() {
    return Positioned(
        right: 20,
        bottom: 60,

        ///加个淡入淡出效果
        child: AnimatedOpacity(
            opacity: isShowFloatButton ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: FloatingActionButton(
              heroTag: 'trend_up_first',
              onPressed: () {
                ///显示的时候才响应点击事件
                if (isShowFloatButton) {
                  ///回到顶部
                  controller.animateTo(0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear);
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.keyboard_arrow_up),
            )));
  }

  ///ListView
  ListView listviewBuild() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return itemView(index);
      },
      controller: controller,
      itemCount: _trendList.length,
    );
  }

  ///具体条目
  Widget itemView(int index) {
//    print('具体条目索引  $index');
    return InkWell(
      onTap: () {
        ///跳转到webview
        RouteUtil.routeToWeb(context, _trendList[index].url,
            title: _trendList[index].title);
      },
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                width: YScreenUtil.getWinWidth() - 20,
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _trendList[index].title,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600),
                      softWrap: true,
                    ),
                    SizedBox(
                      height: 18,
                    ),

                    ///作者
                    Text(
                      'author: ${_trendList[index].author}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                      softWrap: true,
                    ),
                    SizedBox(
                      height: 6,
                    ),

                    ///日期
                    Text(
                      'date: ${DateUtil.formatDate(DateTime.parse(_trendList[index].dateS), format: 'yyyy年MM月dd日')}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                      softWrap: true,
                    )
                  ],
                ),
              ),

              ///添加分割线
              Divider(
                color: Colors.grey,
                height: 0.5,
              )
            ],
          )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
