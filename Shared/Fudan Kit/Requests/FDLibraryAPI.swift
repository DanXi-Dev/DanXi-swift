import Foundation
import SwiftSoup

struct FDLibraryAPI {
    static func getLibrarySeats() async throws -> [Int] {
        // cannot access from outside campus
        let url = URL(string: "http://10.55.101.62/book/show")!
        do {
            let (data, _) = try await sendRequest(URLRequest(url: url))
            let elementList = try processHTMLDataList(data, selector: "div.ceng.nowap > span:nth-child(1)")
            var libraryPeopleList = [0, 0, 0, 0, 0] // 理图，文图，张江，枫林，江湾
            var idx = 0
            for library in elementList {
                guard idx < libraryPeopleList.count else { break }
                guard let content = try? library.html() else { continue }
                guard let number = Int(content.trimmingPrefix("当前在馆人数：")) else { continue }
                libraryPeopleList[idx] = number
                idx += 1
            }
            
            return libraryPeopleList
        } catch NetworkError.networkError {
            throw FDError.campusOnly
        }
    }
}


















let htmlData = """
<!DOCTYPE html
    PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <meta http-equiv="refresh" content="60">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <meta http-equiv="X-UA-Compatible" content="chrome=1,IE=edge" />
    <title>图书馆在馆展示系统</title>
    <!-- Bootstrap -->
    <link href="/Public/newweb/Content/vendors/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet">
    <!--[if lte IE 6]>
    <link rel="stylesheet" type="text/css" href="/Public/newweb/Content/vendors/bootstrap/dist/css/bootstrap-ie6.css">
    <![endif]-->
    <!--[if lte IE 7]>
    <link rel="stylesheet" type="text/css" href="/Public/newweb/Content/vendors/bootstrap/dist/css/ie.css">
    <![endif]-->
    <!-- Font Awesome -->
    <link href="/Public/newweb/Content/vendors/font-awesome/css/font-awesome.min.css" rel="stylesheet">
    <!-- Custom Theme Style -->
    <link href="/Public/newweb/Content/build/css/custom.min.css" rel="stylesheet">
    <link href="/Public/newweb/Content/style.css" rel="stylesheet" type="text/css" />
    <!--jquery-->
    <script src="/Public/newweb/Content/vendors/jquery/dist/jquery.min.js"></script>
    <!-- Bootstrap -->
    <script src="/Public/newweb/Content/vendors/bootstrap/dist/js/bootstrap.min.js"></script>
    <!--框架样式-->
    <link href="/Public/newweb/Content/ske/css/frame.css" rel="stylesheet" type="text/css" />
    <!--二维码生成-->
    <script src="/Public/newweb/Content/ske/distribute/qrcode.js"></script>
    <style type="text/css">
        body {
            background-image: url("/Public/newweb/Content/ske/show/底图.jpg");
            background-repeat: no-repeat;
            background-size: 100%;
            color: #000;
            background-color: #051E3D !important;
            padding: 79px;
        }

        #image img {}
    </style>
</head>

<body>
    <div class="col-xs-5" id="image" style="margin-top:100px;">
        <img src="/Public/newweb/Content/ske/show/舟山图片.png" width="100%" />
    </div>
    <div class="col-xs-7">
        <!--图书馆校区列表-->
        <!--<div class="col-xs-12 xiaoqutitle">
            <div class="col-xs-12" style="text-align:center; float:none; margin:0 auto;">
                <h1 style="font-size:60px;">入馆须知</h1>
                <h1 style="font-size:40px;">（英文）</h1>
            </div>
        </div>-->
        <div class="col-xs-12 xiaoqu row">
            <div class="x_panel" style="font-size:30px; border:0; background:none; text-align:left;">
                <div class="col-xs-12" style="font-size:30px; margin-top:50px;">
                    <span style="font-size:60px; font-weight:bold">入馆须知 </span>
                    <span id="explain_cn">
                        请自觉遵守防疫法规，有症状不入馆。
                        自觉接受体温测量，服从引导和安排。自觉做好个人防护，保持安全距离，消毒借还图书。
                    </span>
                </div>
                <div class="col-xs-12" style="font-size:30px; margin-top:50px;">
                    <span style="font-size:60px; font-weight:bold">Notice : </span>
                    <span id="explain_en">
                        Please abide by the epidemic
                        control and prevention regulations. Do not enter the library if you have any coronavirus
                        symptoms. Please accept the temperature check and follow the guidance and arrangements.
                        Personal protection and a safe distance are required. Please disinfect the books borrowed
                        or returned。
                    </span>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：1200人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：626</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：900人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：275</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：1000人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：236</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：550人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：110</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：800人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：254</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="col-xs-12" style="font-size:60px; margin:40px 0; text-align:left;  margin-top:80px;">
                    <!--<div class="ceng nowap">
                            <span>当前可预约人数：580人</span>
                            <br/>
                            <span style="font-size:30px;">英文</span>
                        </div>-->
                    <div class="ceng nowap">
                        <span>当前在馆人数：302</span>
                        <br />
                        <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                    </div>
                    <!--<div class="ceng nowap">
                            <span>剩余可预约人数：</span>
                            <br/>
                            <span style="font-size:30px;">（ Current Number of People in Library ）</span>
                        </div>-->
                    <div class="clearfix"></div>
                </div>
                <div class="clearfix"></div>
            </div>
            <div class="clearfix"></div>
        </div>
        <!--<div class="col-xs-12">
            <div class="col-xs-12" style="font-size:30px; positon:relative; text-align:left; padding-top:80px; float:none; margin:0 auto;">
                预约入馆二维码：<div id="qrcode" style=" position:absolute; left:250px; top:0px;"></div>
            </div>
        </div>-->
    </div>
</body>
<script>
    $(document).ready(function () {
        //获取网页传参
        var $_GET = (function () {
            var url = window.document.location.href.toString();
            var u = url.split("?");
            if (typeof (u[1]) == "string") {
                u = u[1].split("&");
                var get = {};
                for (var i in u) {
                    var j = u[i].split("=");
                    get[j[0]] = j[1];
                }
                return get;
            } else {
                return {};
            }
        })();
        var explain = {
            type1: { "cn": "读者每天预约上限为3次，开馆后预约当天入馆成功过需在2小时内刷卡入馆，预约次日入馆需在次日10：00前入馆，刷卡离馆后需重新预约。疫情防控期间，为满足本校师生教学、科研、学习的需求，降低人员流动和聚集带来的风险，即日起，图书馆采取预约进馆的开放方式。读者每天预约入馆的上限为4次，可预约当天（需在预约后1小时内刷卡入馆）或次日（需在次日10点前刷卡入馆）的入馆名额。", "en": "英文介绍", "image": "/Public/newweb/Content/ske/images/bg1.png" },
            type2: { "cn": "中文介绍2", "en": "英文介绍2", "image": "/Public/newweb/Content/ske/images/bg1.png" },
            type3: { "cn": "中文介绍3", "en": "英文介绍3", "image": "/Public/newweb/Content/ske/images/bg1.png" },
        };
        if ($_GET["type"] != null) {
            $("#explain_cn")[0].innerText = explain["type" + $_GET["type"]].cn;
            $("#explain_en")[0].innerText = explain["type" + $_GET["type"]].en;
            $("#image img").attr("src", explain["type" + $_GET["type"]].image);
            /*new QRCode("qrcode", {
                text: explain["type"+$_GET["type"]].link,
                width: 200,
                height: 200,
                colorDark : "#000000",
                colorLight : "#ffffff",
                correctLevel : QRCode.CorrectLevel.H
            });*/
        }
    });
</script>

</html>
""".data(using: String.Encoding.utf8)!
