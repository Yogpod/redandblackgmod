
var scope = null
var rootScope = null;

function ControllerMain( $scope, $element, $rootScope )
{
	$rootScope.ShowBack = false;

	scope = $scope;
	rootScope = $rootScope;

	$scope.NewsList = [];
	$scope.CurrentNewsItem = null;
}

function UpdateNewsList( newslist )
{

}
