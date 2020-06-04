window.addEventListener('load', function initMap () {
  //マップを生成して表示
  var routesmap = new google.maps.Map(document.getElementById('routes'), {
    center: {lat: 35.681167, lng: 139.767052},
    zoom: 15
  });
  //情報ウィンドウのインスタンスの生成
  var infoWindow = new google.maps.InfoWindow;

  //ブラウザが Geolocation に対応しているかを判定
  //対応していない場合の処理
  if(!navigator.geolocation){
    //情報ウィンドウの位置をマップの中心位置に指定
    infoWindow.setPosition(routesmap.getCenter());
    //情報ウィンドウのコンテンツを設定
    infoWindow.setContent('Geolocation に対応していません。');
    //情報ウィンドウを表示
    infoWindow.open(routesmap);
  }

  //ブラウザが対応している場合、position にユーザーの位置情報が入る
  navigator.geolocation.getCurrentPosition(function(position) {
    //[スタート地点]
    //position から緯度経度（ユーザーの位置）のオブジェクトを作成し変数に代入
    var pos = {
      lat: position.coords.latitude,
      lng: position.coords.longitude
    };
    //[到着地点]
    //gon gemで定義したmapモデル内のlatitudeとlongitudeを使用
    var latlng = {
      lat: gon.lat,
      lng: gon.lng
    };

    //DirectionsService のオブジェクトを生成
    var directionsService = new google.maps.DirectionsService();
    //DirectionsRenderer のオブジェクトを生成
    var directionsRenderer = new google.maps.DirectionsRenderer();
    //directionsRenderer と地図を紐付け
    directionsRenderer.setMap(routesmap);

    // ルートを取得するリクエスト
    var request = {
      origin: pos,      // 出発地点の緯度経度（ユーザーの位置）
      //gon gemで定義した目的地をlatlngに格納したものを使用
      destination: latlng, // 到着地点
      travelMode: 'DRIVING',  //ドライブ（デフォルト）
    };

    //DirectionsService のオブジェクトのメソッド route() にリクエストを渡し、
    //コールバック関数で結果を setDirections(result) で directionsRenderer にセットして表示
    directionsService.route(request,
      function(result, status) {//ステータスがOKの場合、
        if (status === 'OK') {
          directionsRenderer.setDirections(result);     //取得したルート（結果：result）をセット
          var directionsData = result.routes[0].legs[0];//（結果：result）から、取得したlegs以下のステータスをdirectionsDataに代入。
          document.getElementById('msg_d').innerHTML += directionsData.distance.text　// 変数　directionsData　内の distanceをhtmlで取得
          document.getElementById('msg_t').innerHTML += directionsData.duration.text　// 変数　directionsData　内の durationをhtmlで取得
        }else{
          alert("取得できませんでした：" + status);
      }
    });

  }, function() {  //位置情報の取得をユーザーがブロックした場合のコールバック
    //情報ウィンドウの位置をマップの中心位置に指定
    infoWindow.setPosition(routesmap.getCenter());
    //情報ウィンドウのコンテンツを設定
    infoWindow.setContent('Error: あなたの現在地が取得できませんでした。');
    //情報ウィンドウを表示
    infoWindow.open(routesmap);
  });
});