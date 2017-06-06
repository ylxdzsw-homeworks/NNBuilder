module Keras

using PyCall

@pyimport keras.models       as models
@pyimport keras.layers       as layers
@pyimport keras.layers.merge as merges
@pyimport keras.optimizers   as optimizers
@pyimport keras.callbacks    as callbacks
@pyimport keras.backend      as K

const Model      = models.Model
const load_model = models.load_model

const Activation             = layers.Activation
const ActivityRegularization = layers.ActivityRegularization
const AtrousConv2D           = layers.AtrousConv2D
const AtrousConvolution2D    = layers.AtrousConvolution2D
const AveragePooling1D       = layers.AveragePooling1D
const AveragePooling2D       = layers.AveragePooling2D
const AveragePooling3D       = layers.AveragePooling3D
const BatchNormalization     = layers.BatchNormalization
const Conv1D                 = layers.Conv1D
const Conv2D                 = layers.Conv2D
const Conv3D                 = layers.Conv3D
const Convolution1D          = layers.Convolution1D
const Convolution2D          = layers.Convolution2D
const Convolution3D          = layers.Convolution3D
const Deconv2D               = layers.Deconv2D
const Deconvolution2D        = layers.Deconvolution2D
const Dense                  = layers.Dense
const Dropout                = layers.Dropout
const ELU                    = layers.ELU
const Embedding              = layers.Embedding
const Flatten                = layers.Flatten
const GRU                    = layers.GRU
const GaussianDropout        = layers.GaussianDropout
const GaussianNoise          = layers.GaussianNoise
const Highway                = layers.Highway
const Input                  = layers.Input
const InputLayer             = layers.InputLayer
const InputSpec              = layers.InputSpec
const LSTM                   = layers.LSTM
const Lambda                 = layers.Lambda
const LeakyReLU              = layers.LeakyReLU
const LocallyConnected1D     = layers.LocallyConnected1D
const LocallyConnected2D     = layers.LocallyConnected2D
const Masking                = layers.Masking
const MaxPooling1D           = layers.MaxPooling1D
const MaxPooling2D           = layers.MaxPooling2D
const MaxPooling3D           = layers.MaxPooling3D
const MaxoutDense            = layers.MaxoutDense
const Merge                  = layers.Merge
const PReLU                  = layers.PReLU
const Permute                = layers.Permute
const RepeatVector           = layers.RepeatVector
const Reshape                = layers.Reshape
const SeparableConv2D        = layers.SeparableConv2D
const SeparableConvolution2D = layers.SeparableConvolution2D
const SimpleRNN              = layers.SimpleRNN
const ThresholdedReLU        = layers.ThresholdedReLU
const TimeDistributed        = layers.TimeDistributed
const UpSampling1D           = layers.UpSampling1D
const UpSampling2D           = layers.UpSampling2D
const UpSampling3D           = layers.UpSampling3D
const Wrapper                = layers.Wrapper
const ZeroPadding1D          = layers.ZeroPadding1D
const ZeroPadding2D          = layers.ZeroPadding2D
const ZeroPadding3D          = layers.ZeroPadding3D

const Add         = merges.Add
const Average     = merges.Average
const Concatenate = merges.Concatenate
const Dot         = merges.Dot
const Maximum     = merges.Maximum
const Multiply    = merges.Multiply

const Adadelta = optimizers.Adadelta
const Adagrad  = optimizers.Adagrad
const Adam     = optimizers.Adam
const Adamax   = optimizers.Adamax
const Nadam    = optimizers.Nadam
const RMSprop  = optimizers.RMSprop
const SGD      = optimizers.SGD

const ProgbarLogger         = callbacks.ProgbarLogger
const ModelCheckpoint       = callbacks.ModelCheckpoint
const EarlyStopping         = callbacks.EarlyStopping
const RemoteMonitor         = callbacks.RemoteMonitor
const LearningRateScheduler = callbacks.LearningRateScheduler
const ReduceLROnPlateau     = callbacks.ReduceLROnPlateau
const CSVLogger             = callbacks.CSVLogger
const LambdaCallback        = callbacks.LambdaCallback

const dim_ordering = K.image_dim_ordering()

end
