import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'net_const.dart';
import 'net_exception.dart';

/// 网络请求管理类抽象层

/// 负责执行网络请求的通用逻辑

/// 不同项目的不同配置交给上层实现

abstract class AbstractDioManager {
  
  Dio dio;

  AbstractDioManager() {
    dio = new Dio(configBaseOptions());
    configDio();
  }

  //get请求
  Future<T> get<T>(String url, {params, options,token}) async {
    return _requestHttp<T>(url, Method.GET, params: params,cancelToken:token);
  }

  //post请求
  Future<T> post<T>(String url, {params, options,token}) async {
    return _requestHttp<T>(url, Method.POST, params: params,cancelToken:token);
  }

  Future<T> delete<T>(String url, {params, options,token}) async {
    return _requestHttp<T>(url, Method.DELETE, params: params,cancelToken:token);
  }

  Future<T> put<T>(String url, {params, options,token}) async {
    return _requestHttp<T>(url, Method.PUT, params: params,cancelToken:token);
  }

  Future<T> _requestHttp<T>(String url, Method method, {params, options,cancelToken}) async {
    Response response;
    debugPrint("url: $url");
    debugPrint("params: $params");
    try {
      if (method == Method.GET) {
        response = await dio.get(url, queryParameters: params, options: options,cancelToken: cancelToken);
      } else if (method == Method.POST) {
        response = await dio.post(url, data: params, options: options,cancelToken: cancelToken);
      } else if (method == Method.DELETE) {
        response = await dio.delete(url, data: params, options: options,cancelToken: cancelToken);
      } else if (method == Method.PUT) {
        response = await dio.put(url, data: params, options: options,cancelToken: cancelToken);
      }
    } on DioError catch (error) {
      throw getHttpErrorResult(error);
    } catch (error) {
      debugPrint("net error $error");
    }
    //优先解析请求是否出错
    if (isSuccess(response)) {
      throw getBusinessErrorResult(getCode(response), getMessage(response));
    }
    //确保请求成功的情况下，再实例化数据
    T data;
    try {
      data = decode<T>(response);
    } catch (e) {
      throw getBusinessErrorResult(HttpCode.PARSE_JSON_ERROR, "json parse error~");
    }
    return data;
  }

  ///具体的解析逻辑上层实现
  T decode<T>(Response response);

  ///业务逻辑报错映射
  NetWorkException getBusinessErrorResult(int code, String error);

  /// HTTP层网络请求错误翻译
  NetWorkException getHttpErrorResult(DioError e);

  ///初始化dio参数
  BaseOptions configBaseOptions();

  ///判断业务层的返回成功还是失败，失败后报错，成功后进行数据解析
  bool isSuccess(Response response);

  ///默认是“code”获取response code 若服务器请求返回的code的key不一样,请重写此方法
  int getCode(Response response) {
    return response.data["code"];
  }

  ///默认是“message”获取response message 若服务器请求返回的message的key不一样,请重写此方法
  String getMessage(Response response) {
    return response.data["message"];
  }

  ///dio的配置工作，进行添加拦截器等操作
  void configDio();
}
