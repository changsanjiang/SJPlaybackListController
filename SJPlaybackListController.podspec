#
# Be sure to run `pod lib lint SJPlaybackListController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SJPlaybackListController'
  s.version          = '0.0.4'
  s.summary          = 'SJBaseVideoPlayer 播放列表控制器.'
  s.description      = <<-DESC
  播放列表控制器: 1. 播放模式: 单曲/循环/随机. 2: 播放列表控制
                       DESC
  s.homepage         = 'https://github.com/changsanjiang/SJPlaybackListController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SanJiang' => 'changsanjiang@gmail.com' }
  s.source           = { :git => 'https://github.com/changsanjiang/SJPlaybackListController.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.source_files = 'SJPlaybackListController/*.{h,m}'

  s.subspec 'Core' do |ss|
    ss.source_files = 'SJPlaybackListController/Core/*.{h,m}'
  end

  #s.dependency 'SJBaseVideoPlayer'
end
